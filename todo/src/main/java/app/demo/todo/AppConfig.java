package app.demo.todo;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

import com.azure.identity.AzureCliCredential;
import com.azure.identity.AzureCliCredentialBuilder;
import com.azure.identity.ManagedIdentityCredential;
import com.azure.identity.ManagedIdentityCredentialBuilder;

import app.demo.todo.utils.AppLogger;

//https://www.azureblue.io/how-to-authenicated-aad-identity-against-postgres-using-spring-boot/
@Configuration
@ConfigurationProperties(prefix = "app.demo.todo")
public class AppConfig {
    public static final AppLogger LOGGER = new AppLogger(AppConfig.class);

    private String applicationClientId;
    private String loadDemoData;
    private String debugAuthToken;
    private String testKeyvaultReference;

    // Token identity for AAD integration while running on local machine
    @Bean
    @Profile("local-mi")
    public AzureCliCredential azureCliCredential() {
        return new AzureCliCredentialBuilder().build();
    }

    // Token identity for AAD integration while running in Azure
    @Bean
    @Profile({ "test-mi", "prod-mi" })
    public ManagedIdentityCredential managedIdentityCredentialTest() {

        LOGGER.debug(String.format("Connecting to the database using Application ClientID '%s'", applicationClientId));
        return new ManagedIdentityCredentialBuilder()
                .clientId(applicationClientId)
                .build();
    }

    public void setApplicationClientId(String applicationClientId) {
        this.applicationClientId = applicationClientId;
    }

    public void setLoadDemoData(String loadDemoData) {
        this.loadDemoData = loadDemoData;
    }

    public void setDebugAuthToken(String debugAuthToken) {
        this.debugAuthToken = debugAuthToken;
    }

    public String getApplicationClientId() {
        return applicationClientId;
    }

    public boolean getLoadDemoData() {
        return loadDemoData != null && loadDemoData.toLowerCase().trim().equals("true");
    }

    public boolean getDebugAuthToken() {
        return debugAuthToken != null && debugAuthToken.toLowerCase().trim().equals("true");
    }

    public String getTestKeyvaultReference() {
        return testKeyvaultReference;
    }

    public void setTestKeyvaultReference(String testKeyvaultReference) {
        LOGGER.debug(String.format("TEST_KEYVAULT_REFERENCE: '%s'", testKeyvaultReference));
        this.testKeyvaultReference = testKeyvaultReference;
    }

    public String getVersion() {
        String version = "Unknown";
        try {
            version = this.getClass().getPackage().getImplementationVersion();
        } catch (Exception ignoreException) {
            LOGGER.error("An error has occurred while trying to retrieve the package version.");
        }
        return version;
    }

    public String getEnvironment() {
        String environment = "Unknown";
        return environment;
    }
    
}
