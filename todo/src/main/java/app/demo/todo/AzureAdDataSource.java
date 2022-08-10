package app.demo.todo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.azure.core.credential.SimpleTokenCache;
import com.azure.core.credential.TokenCredential;
import com.azure.core.credential.TokenRequestContext;
import com.zaxxer.hikari.HikariDataSource;

import app.demo.todo.utils.FileCache;

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

    public static final String BALTIMORE_CYBER_TRUST_ROOT = new FileCache().cacheEmbededFile("BaltimoreCyberTrustRoot.crt.pem");
    public static final String DIGICERT_GLOBAL_ROOT = new FileCache().cacheEmbededFile("DigiCertGlobalRootCA.crt.pem");
    
    private final SimpleTokenCache cache;

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

        var token = accessToken.getToken();
        LOGGER.debug(token);
        
        return token;
    }

    private static TokenRequestContext createRequestContext() {
        return new TokenRequestContext().addScopes("https://ossrdbms-aad.database.windows.net/.default");
    }
}
