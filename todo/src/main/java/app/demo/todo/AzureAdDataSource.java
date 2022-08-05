package app.demo.todo;

import com.azure.core.credential.SimpleTokenCache;
import com.azure.core.credential.TokenCredential;
import com.azure.core.credential.TokenRequestContext;
import com.zaxxer.hikari.HikariDataSource;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

//https://www.azureblue.io/how-to-authenicated-aad-identity-against-postgres-using-spring-boot/
@Component
@ConfigurationProperties(prefix = "spring.datasource")
public class AzureAdDataSource extends HikariDataSource {

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

        return accessToken.getToken();
    }

    private static TokenRequestContext createRequestContext() {
        return new TokenRequestContext().addScopes("https://ossrdbms-aad.database.windows.net/.default");
    }
}
