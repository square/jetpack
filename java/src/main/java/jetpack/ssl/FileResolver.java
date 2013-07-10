package jetpack.ssl;

import java.io.File;
import java.io.FileNotFoundException;

/** Simple interface to resolve {@link java.io.File}s. */
public interface FileResolver {
  /**
   * @return resolved File object.
   * @throws java.io.FileNotFoundException when file not found.
   */
  File resolve() throws FileNotFoundException;

  /** @return The path to search for files. */
  String getSearchPath();
}
