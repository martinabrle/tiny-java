package app.demo.todo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.azure.core.credential.SimpleTokenCache;
import com.azure.core.credential.TokenCredential;
import com.azure.core.credential.TokenRequestContext;
import com.zaxxer.hikari.HikariDataSource;

import java.io.IOException;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

//https://www.azureblue.io/how-to-authenicated-aad-identity-against-postgres-using-spring-boot/
//TODO: Review working with profiles: I need to be able to do the following:
//  1) Use H2 for local development
//  2) Use AzureCliCredentialconnect for local testing
//  3) Use ManagedIdentityCredentialBuilder for UAT, PROD,...
//  4) But also be able to use the old username/password for backward compatibility 
@Component
@ConfigurationProperties(prefix = "spring.datasource")
@Profile({"local-mi","test-mi", "prod-mi"})
public class AzureAdDataSource extends HikariDataSource {

    public static final Logger LOGGER = LoggerFactory.getLogger(AzureAdDataSource.class);

    private final SimpleTokenCache cache;

	public static final String CURRENT_DIR = GetCurrentDirectory();
	public static final String CURRENT_SYSTEM_DIR = GetSystemCurrentDirectory();

    public AzureAdDataSource(TokenCredential credential) {
        this.cache = new SimpleTokenCache(() -> credential.getToken(createRequestContext()));
    }

    @Override
    public String getPassword() {
        var accessToken = cache
                .getToken()
                .retry(1L)
                .blockOptional()
                .orElseThrow(() -> new RuntimeException("Attempt to retrieve AAD token failed"));

        return accessToken.getToken();
    }

    private static TokenRequestContext createRequestContext() {
        return new TokenRequestContext().addScopes("https://ossrdbms-aad.database.windows.net/.default");
    }

    public static String GetCurrentDirectory() {
		String currentPath = "";

		try {
			currentPath = new java.io.File(".").getCanonicalPath();
		} catch (IOException ignoreException) {
			LOGGER.error("ERROR: IO Exception ocurred while querying user's current directory.");
		}
		LOGGER.warn("Current dir:" + currentPath);

		return currentPath;
	}

	public static String GetSystemCurrentDirectory() {

		String currentDir = System.getProperty("user.dir");
        LOGGER.warn("Current dir using System:" + currentDir);

		return currentDir;
	}
}
