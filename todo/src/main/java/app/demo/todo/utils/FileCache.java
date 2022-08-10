package app.demo.todo.utils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

public class FileCache {
    public static final Logger LOGGER = LoggerFactory.getLogger(FileCache.class);

    public String cacheEmbededFile(String fileName) {

        LOGGER.error("Starting 'cacheEmbededFile'....");

        File file = new File(fileName);

        LOGGER.error("Trying to cache resource " + fileName + " into the local file " + file.getAbsolutePath());

        try {
            LOGGER.error("Trying to retrieve a resource file " + fileName + " from resources.");
            InputStream link = (this.getClass().getClassLoader().getResourceAsStream(fileName));
            if (link == null) {
                LOGGER.error("Resource file not found");
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

        LOGGER.error("Finishin 'cacheEmbededFile' with a return value " + file.getAbsolutePath() + "....");
        return file.getAbsolutePath();
    }
}
