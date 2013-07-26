package jetpack.ssl;

import java.io.File;
import java.io.FileNotFoundException;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import static org.fest.assertions.api.Assertions.assertThat;

public class VersionedFileResolverTest {
  @Rule public TemporaryFolder tempDir = new TemporaryFolder();

  @Test public void loadsLatest() throws Exception {
    File base = tempDir.newFile("foo.txt");

    FileResolver fileResolver = new VersionedFileResolver(base);
    assertThat(fileResolver.resolve()).isEqualTo(base);

    File v2 = tempDir.newFile("foo.txt..2");
    assertThat(fileResolver.resolve()).isEqualTo(v2);

    File v4 = tempDir.newFile("foo.txt..4");
    assertThat(fileResolver.resolve()).isEqualTo(v4);

    tempDir.newFile("foo.txt..3");
    assertThat(fileResolver.resolve()).isEqualTo(v4);
  }

  @Test public void testIgnoresFilesWithoutVersionIdentifier() throws Exception {
    File base = tempDir.newFile("bar.txt");
    FileResolver fileResolver = new VersionedFileResolver(base);

    // This should get ignored because it doesn't contain the versioned file prefix
    tempDir.newFile("bar.txt.bak");
    assertThat(fileResolver.resolve()).isEqualTo(base);
  }

  @Test(expected = FileNotFoundException.class)
  public void testThrowsWhenFileNotFound() throws Exception {
    FileResolver fileResolver = new VersionedFileResolver(
        new File(tempDir.getRoot(), "dne.txt"));

    fileResolver.resolve();
  }

  @Test public void resolvesVersionsIfBaseFileDoesNotExist() throws Exception {
    File v1 = tempDir.newFile("baz.txt..v1");

    FileResolver fileResolver = new VersionedFileResolver(
        new File(tempDir.getRoot(), "baz.txt"));

    assertThat(fileResolver.resolve()).isEqualTo(v1);
  }

  @Test(expected = IllegalArgumentException.class)
  public void testThrowsWhenBasePathIsDirectory() throws Exception {
    new VersionedFileResolver(tempDir.getRoot());
  }

  @Test(expected = IllegalArgumentException.class)
  public void testThrowsWhenParentDirectoryDoesNotExist() throws Exception {
    new VersionedFileResolver(new File(tempDir.getRoot(), "food/donut.txt"));
  }
}

