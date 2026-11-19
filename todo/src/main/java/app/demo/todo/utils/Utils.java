package app.demo.todo.utils;

import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Date;

public class Utils {
    private static final DateTimeFormatter DATE_FORMAT =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm a z");

    public static Long epochMillis(Date date) {
        return date == null ? null : date.getTime();
    }

    public static String toJsonValueContent(String value) {
        if (value == null)
          return "null";
        return value.replace("\'", "\\'").replace("\"", "\\\"");
    }
    
    public static String toJsonValueContent(Date value) {
        if (value == null)
          return "null";
        return DATE_FORMAT.format(Instant.ofEpochMilli(value.getTime()).atZone(ZoneId.systemDefault()));
    }

    public static String shortenString(String value) {
			
      if (value == null) {
        return "";
      }
      
      if (value.length() <= 5)
      {
        return value;
      }

      return value.substring(0, 4) + "...";
    }
}
