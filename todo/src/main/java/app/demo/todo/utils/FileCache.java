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

        LOGGER.info("Starting 'cacheEmbededFile'....");

        File file = new File(fileName);

        LOGGER.info("Retrieving resource " + fileName + "and saving it into a local file " + file.getAbsolutePath());

        if (Files.notExists(Paths.get(fileName))) {
            try {
                LOGGER.info("Retrieving a file " + fileName + " from embeded resources.");
                InputStream link = (this.getClass().getClassLoader().getResourceAsStream(fileName));
                if (link == null) {
                    LOGGER.error("Embeded resource file not found");
                }

                byte[] buffer = link.readAllBytes();

                File targetFile = new File(fileName);
                var outStream = new FileOutputStream(targetFile);
                outStream.write(buffer);
                outStream.flush();
                outStream.close();
            } catch (Exception ex) {
                LOGGER.error("ERROR: IO Exception ocurred while querying user's current directory: {}", ex);
            }
        } else {
            LOGGER.info("Resource file " + fileName + " fis already cached as " + Paths.get(fileName).getFileName().toAbsolutePath().toString() + ".");
        }

        LOGGER.info("Finishin 'cacheEmbededFile' with a return value " + file.getAbsolutePath() + "....");
        return file.getAbsolutePath();
    }
}
