package jetpack.ssl;

import com.google.common.base.Predicate;
import com.google.common.base.Throwables;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.Iterables;
import com.google.common.collect.Iterators;
import com.google.common.collect.Lists;
import com.google.common.io.Closer;
import com.google.common.util.concurrent.ThreadFactoryBuilder;
import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.net.Socket;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.Principal;
import java.security.PrivateKey;
import java.security.UnrecoverableKeyException;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ThreadFactory;
import javax.net.ssl.X509KeyManager;
import org.joda.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static com.google.common.base.Preconditions.checkArgument;
import static com.google.common.base.Preconditions.checkNotNull;
import static java.util.concurrent.TimeUnit.SECONDS;

/** X509KeyManager which periodically looks for a newer key and transparently reloads. */
public class ReloadingKeyManager implements X509KeyManager {
  public static final Duration DEFAULT_RELOAD_INTERVAL = Duration.standardHours(2);
  private static final Logger logger = LoggerFactory.getLogger(ReloadingKeyManager.class);

  private final ThreadFactory namedThreadFactory =
      new ThreadFactoryBuilder().setNameFormat("reloading-key-manager").build();
  private final ScheduledExecutorService reloadScheduler =
      Executors.newSingleThreadScheduledExecutor(namedThreadFactory);
  private final FileResolver fileResolver;
  private final char[] pin;
  private final String keyStoreType;
  private final Duration reloadInterval;

  private volatile KeyStore keyStore;
  private volatile String keyName;

  /**
   * @param fileResolver which resolves a {@link java.io.File} for a {@link java.security.KeyStore}.
   * @param pin KeyStore password.
   * @param keyStoreType KeyStore type.
   */
  public ReloadingKeyManager(FileResolver fileResolver, char[] pin, String keyStoreType) {
    this(fileResolver, pin, keyStoreType, DEFAULT_RELOAD_INTERVAL);
  }

  /**
   * @param fileResolver which resolves a {@link File} for a {@link KeyStore}.
   * @param pin KeyStore password.
   * @param keyStoreType KeyStore type.
   * @param reloadInterval custom interval to re-resolve and reload the KeyStore.
   *        If null or Duration.ZERO, the KeyStore is loaded once.
   */
  public ReloadingKeyManager(FileResolver fileResolver, char[] pin, String keyStoreType,
      Duration reloadInterval) {
    this.fileResolver = checkNotNull(fileResolver);
    this.pin = checkNotNull(pin);
    this.keyStoreType = checkNotNull(keyStoreType);
    this.reloadInterval = reloadInterval;

    loadKeyStore();
    reloadKeyStoreOnInterval();
  }

  /** @return interval between keystore reloads. */
  public Duration getReloadInterval() {
    return reloadInterval;
  }

  @Override
  public String[] getClientAliases(String string, Principal[] principals) {
    return new String[] {keyName};
  }

  @Override
  public String chooseClientAlias(String[] strings, Principal[] principals, Socket socket) {
    return keyName;
  }

  @Override
  public String[] getServerAliases(String string, Principal[] principals) {
    return new String[] {keyName};
  }

  @Override
  public String chooseServerAlias(String string, Principal[] principals, Socket socket) {
    return keyName;
  }

  @Override
  public X509Certificate[] getCertificateChain(String alias) {
    checkArgument(!alias.isEmpty());
    try {
      Certificate[] certs = keyStore.getCertificateChain(alias);
      if (certs == null) {
        logger.error("No certificate chain is found for alias: %s", alias);
        throw new KeyStoreException("No certificate chain is found for alias: " + alias);
      }

      List<X509Certificate> x509Certs = Lists.newArrayList();
      for (Certificate cert : certs) {
        if (cert instanceof X509Certificate) {
          x509Certs.add((X509Certificate) cert);
        }
      }
      return x509Certs.toArray(new X509Certificate[x509Certs.size()]);
    } catch (KeyStoreException e) {
      throw Throwables.propagate(e);
    }
  }

  @Override
  public PrivateKey getPrivateKey(String keyAlias) {
    checkArgument(!keyAlias.isEmpty());
    try {
      return (PrivateKey) keyStore.getKey(keyAlias, pin);
    } catch (KeyStoreException e) {
      // KeyStore is initialized at construction, so this should not occur.
      throw new AssertionError(e);
    } catch (NoSuchAlgorithmException e) {
      throw new RuntimeException("Algorithm for reading key not available", e);
    } catch (UnrecoverableKeyException e) {
      throw new RuntimeException("Invalid password for reading key " + keyAlias, e);
    }
  }

  private void reloadKeyStoreOnInterval() {
    if (Duration.ZERO.isEqual(reloadInterval)) return;

    Runnable loader = new Runnable() {
      public void run() {
        logger.info("Checking for new keystore to load at path {}", fileResolver.getSearchPath());
        try {
          loadKeyStore();
          logger.info("Completed reloading keystore.");
        } catch (Exception e) {
          logger.error("Keystore reload failed", e);
        }
      }
    };

    reloadScheduler.scheduleAtFixedRate(loader,
        reloadInterval.getStandardSeconds(),
        reloadInterval.getStandardSeconds(),
        SECONDS);
  }

  private void loadKeyStore() {
    File latest;
    try {
      latest = fileResolver.resolve();
    } catch (FileNotFoundException e) {
      throw Throwables.propagate(e);
    }
    logger.info("Resolved latest keystore {}", latest);

    try {
      keyStore = loadKeyStore(latest, keyStoreType, new String(pin));
    } catch (IOException e) {
      throw Throwables.propagate(e);
    }

    List<String> keyAliases = findAliasesOfType(KeyStore.PrivateKeyEntry.class, keyStore);
    keyName = Iterables.getOnlyElement(keyAliases);
  }

  /**
   * Finds all aliases present in the keystore of a given entry type.
   *
   * @param entryClass one of {@link KeyStore.PrivateKeyEntry}, {@link KeyStore.SecretKeyEntry}, or
   *        {@link KeyStore.TrustedCertificateEntry}.
   * @param keyStore keystore containing all the entries.
   * @return List of aliases present of the given type.
   */
  private static List<String> findAliasesOfType(final Class<? extends KeyStore.Entry> entryClass,
      final KeyStore keyStore) {
    Iterator<String> aliasIterator;
    try {
      aliasIterator = Iterators.forEnumeration(keyStore.aliases());
    } catch (KeyStoreException e) {
      throw new RuntimeException("KeyStore not initialized.", e);
    }

    Iterator<String> results = Iterators.filter(aliasIterator,
        new Predicate<String>() {
          @Override public boolean apply(String alias) {
            try {
              return keyStore.entryInstanceOf(alias, entryClass);
            } catch (KeyStoreException e) {
              throw Throwables.propagate(e);
            }
          }
        });
    return ImmutableList.copyOf(results);
  }

  /**
   * Loads an existing keystore from a file.
   *
   * @param keyStoreFile file to load from
   * @param type keystore type
   * @param password optional password to protect keys and keystore with
   * @return the loaded keystore
   * @throws IOException on I/O errors
   */
  public static KeyStore loadKeyStore(File keyStoreFile, String type, String password)
      throws IOException {
    checkNotNull(keyStoreFile);
    checkNotNull(type);
    KeyStore keyStore;
    try {
      keyStore = KeyStore.getInstance(type);
    } catch (KeyStoreException e) {
      throw new RuntimeException("no provider exists for the keystore type " + type, e);
    }

    Closer closer = Closer.create();
    InputStream stream = closer.register(new BufferedInputStream(new FileInputStream(keyStoreFile)));
    try {
      keyStore.load(stream, (password == null) ? null : password.toCharArray());
    } catch (CertificateException e) {
      throw new RuntimeException("some certificates could not be loaded", e);
    } catch (NoSuchAlgorithmException e) {
      throw new RuntimeException("integrity check algorithm is unavailable", e);
    } catch (IOException e) {
      throw new RuntimeException("I/O error or a bad password", e);
    } catch (Throwable e) { // Prescribed Closer pattern.
      throw closer.rethrow(e);
    } finally {
      closer.close();
    }
    return keyStore;
  }
}
