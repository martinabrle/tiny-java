package app.demo.todo.utils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;

public class FileCache {
    public static final Logger LOGGER = LoggerFactory.getLogger(FileCache.class);

    public String cacheEmbededFile(String fileName) {

        LOGGER.debug("Starting 'cacheEmbededFile'....");

        File file = new File(fileName);

        LOGGER.debug(String.format("Retrieving resource '%s' and saving it into a local file '%s'", fileName + file.getAbsolutePath()));

        if (Files.notExists(Paths.get(fileName))) {
            try {
                LOGGER.debug(String.format("Retrieving a file '%s' from embeded resources.", fileName));
                InputStream link = (this.getClass().getClassLoader().getResourceAsStream(fileName));
                if (link == null) {
                    LOGGER.error(String.format("Embeded resource file '%s' not found", fileName));
                }

                byte[] buffer = link.readAllBytes();

                File targetFile = new File(fileName);
                var outStream = new FileOutputStream(targetFile);
                outStream.write(buffer);
                outStream.flush();
                outStream.close();
            } catch (Exception ex) {
                LOGGER.error(String.format("Exception ocurred while querying user's current directory (%s)", ex.getMessage()));
            }
        } else {
            LOGGER.debug(String.format("Resource file '%s' is already cached as '%s'.", fileName, Paths.get(fileName).getFileName().toAbsolutePath().toString()));
        }

        LOGGER.debug(String.format("Exiting 'cacheEmbededFile' with a return value '%s'...", file.getAbsolutePath()));
        return file.getAbsolutePath();
    }
}
