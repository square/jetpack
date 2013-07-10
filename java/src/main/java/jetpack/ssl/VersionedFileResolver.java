package jetpack.ssl;

import com.google.common.collect.Lists;
import com.google.common.collect.Ordering;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FilenameFilter;
import java.util.List;

import static com.google.common.base.Preconditions.checkArgument;
import static java.lang.String.format;

/**
 * Utility for loading the latest version of a file.
 *
 * File names are composed of basename + separator + version, where the separator is <tt>..</tt>.
 * Valid names include <tt>hello.txt</tt>, <tt>hello.txt..0aae825a73e161d8</tt>, and
 * <tt>hello.txt..bafe155a72e1aadb</tt>. The latest version is determined as the lexicographically
 * greatest.
 *
 * {@code
 *    VersionedFiledResolver versionedFileResolver = new VersionedFileResolver("/tmp/hello.txt");
 *    // Assuming /tmp/ contains hello.txt and hello.txt..0aae825a73e161d8
 *    versionedFiledLoader.resolve() // returns new File("/tmp/hello.txt..0aae825a73e161d8");
 *    // Assuming /tmp/ contains only hello.txt
 *    versionedFiledLoader.resolve() // returns new File("/tmp/hello.txt");
 * }
 */
public class VersionedFileResolver implements FileResolver {
  public static final String VERSIONED_FILE_PREFIX = "..";

  private final FilenameFilter filenameFilter;
  private final File baseDirPath;
  private final File basePath;

  /**
   * @param basePath The basename of the versioned file to resolve.
   */
  public VersionedFileResolver(File basePath) {
    checkArgument(!basePath.isDirectory() && basePath.getParentFile().isDirectory());

    this.basePath = basePath;
    this.baseDirPath = basePath.getParentFile();
    final String basename = basePath.getName();

    filenameFilter = new FilenameFilter() {
      @Override public boolean accept(File file, String s) {
        return s.equals(basename) || s.startsWith(basename + VERSIONED_FILE_PREFIX);
      }
    };
  }

  /**
   * @return File path of the lexicographically latest version of the filename, or the base file if
   * it exists and no other versions do.
   * @throws FileNotFoundException if no version of the file can be found
   */
  @Override public File resolve() throws FileNotFoundException {
    String[] list = baseDirPath.list(filenameFilter);
    if (list == null) {
      throw new RuntimeException(
          format("Error performing partial directory listing of '%s', returned null.", baseDirPath));
    }

    List<File> files = Lists.newArrayList();
    for (String filename : list) {
      files.add(new File(baseDirPath, filename));
    }

    if (files.isEmpty()) {
      throw new FileNotFoundException("Could not find any version of \"" + basePath + "\".");
    }

    return Ordering.natural().max(files);
  }

  /** @return The path where versioned files are being searched for. */
  @Override public String getSearchPath() {
    return basePath.getPath();
  }
}
