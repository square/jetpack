package jetpack.ssl;

import com.google.common.io.Resources;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.security.cert.X509Certificate;
import java.util.NoSuchElementException;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import static org.fest.assertions.api.Assertions.assertThat;

public class ReloadingKeyManagerTest {
  final char[] password = "password".toCharArray();

  @Rule public TemporaryFolder tempDir = new TemporaryFolder();

  @Test public void managesKeyStoreWithSingleKey() throws Exception {
    File file = tempDir.newFile("managesKeyStoreWithSingleKey.jceks");
    Resources.copy(Resources.getResource("singleKey.jceks"), new FileOutputStream(file));

    ReloadingKeyManager keyManager =
        new ReloadingKeyManager(staticResolver(file), password, "JCEKS", null);
    assertThat(keyManager.getClientAliases(null, null)).containsOnly("singlekey");
    assertThat(keyManager.getServerAliases(null, null)).containsOnly("singlekey");

    X509Certificate[] certChain = keyManager.getCertificateChain("singlekey");
    assertThat(certChain).hasSize(1);
    assertThat(certChain[0].getSubjectDN().getName()).isEqualTo("CN=singleKey");

    assertThat(keyManager.getPrivateKey("singlekey")).isNotNull();
  }

  @Test(expected = NoSuchElementException.class)
  public void failsForTruststore() throws Exception {
    File file = tempDir.newFile("failsForTruststore.jceks");
    Resources.copy(Resources.getResource("singleCert.jceks"), new FileOutputStream(file));

    new ReloadingKeyManager(staticResolver(file), password, "JCEKS", null);
  }

  @Test(expected = IllegalArgumentException.class)
  public void failsForKeystoreWithMultipleKeys() throws Exception {
    File file = tempDir.newFile("failsForKeystoreWithMultipleKeys.jceks");
    Resources.copy(Resources.getResource("multipleKeys.jceks"), new FileOutputStream(file));

    new ReloadingKeyManager(staticResolver(file), password, "JCEKS", null);
  }

  /** @return FileResolver that always resolves the same file. */
  private static FileResolver staticResolver(final File file) {
    return new FileResolver() {
      @Override public File resolve() throws FileNotFoundException { return file; }
      @Override public String getSearchPath() { return file.getPath(); }
    };
  }
}

