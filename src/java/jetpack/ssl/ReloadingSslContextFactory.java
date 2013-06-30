package jetpack.ssl;

import com.google.common.base.Strings;
import com.google.common.io.Files;
import java.io.File;
import java.io.IOException;
import java.security.GeneralSecurityException;
import java.security.KeyStore;
import javax.net.ssl.KeyManager;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509KeyManager;

import static com.google.common.base.Preconditions.checkArgument;
import static jetpack.ssl.ReloadingKeyManager.loadKeyStore;

/**
 * Builds {@link SSLContext}s from the given configs.
 */
public class ReloadingSslContextFactory {
  private ReloadingSslContextFactory() {}
  private static final String TRUST_ALG = TrustManagerFactory.getDefaultAlgorithm();

  /**
   * Builds a TLS/SunJSSE SSL context given the key and trust store configs.
   */
  public static SSLContext create(String keyStorePath, String keyStorePassword, String keyStoreType,
      String trustStoreFilename, String trustStorePassword)
      throws GeneralSecurityException, IOException {

    checkArgument(!keyStorePath.isEmpty(), "keyStorePath must not be empty.");
    checkArgument(!trustStoreFilename.isEmpty(), "trustStoreFilename must not be empty.");

    // Load the trust store.
    String trustStoreType = Files.getFileExtension(trustStoreFilename).toUpperCase();
    KeyStore trustStore = loadKeyStore(new File(trustStoreFilename), trustStoreType, trustStorePassword);
    TrustManagerFactory trustFactory = TrustManagerFactory.getInstance(TRUST_ALG);
    trustFactory.init(trustStore);

    // Load the key managers.
    char[] passPhrase = Strings.nullToEmpty(keyStorePassword).toCharArray();
    VersionedFileResolver fileResolver = new VersionedFileResolver(new File(keyStorePath));
    X509KeyManager reloadingKeyManager = new ReloadingKeyManager(fileResolver, passPhrase,
        keyStoreType);
    KeyManager[] keyManagers = new KeyManager[] { reloadingKeyManager };

    // Build the SSL context for TLS.
    SSLContext sslContext = SSLContext.getInstance("TLS", "SunJSSE");
    sslContext.init(keyManagers, trustFactory.getTrustManagers(), null);
    return sslContext;
  }
}
