package app.demo.todo;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

import com.azure.identity.AzureCliCredential;
import com.azure.identity.AzureCliCredentialBuilder;
import com.azure.identity.ManagedIdentityCredential;
import com.azure.identity.ManagedIdentityCredentialBuilder;

//https://www.azureblue.io/how-to-authenicated-aad-identity-against-postgres-using-spring-boot/
//TODO: Review working with profiles: I need to be able to do the following:
//  1) Use H2 for local development
//  2) Use AzureCliCredentialconnect for local testing
//  3) Use ManagedIdentityCredentialBuilder for UAT, PROD,...
//  4) But also be able to use the old username/password for backward compatibility 
@Configuration
@ConfigurationProperties(prefix="app.demo.todo")
public class AppConfig {
    private String applicationClientId;
    private String loadDemoData;

    //Token identity for AAD integration while running on local machine
    @Bean
    @Profile("local-mi")
    public AzureCliCredential azureCliCredential() {
        return new AzureCliCredentialBuilder().build();
    }

    //Token identity for AAD integration while running in Azure
    @Bean
    @Profile({"test-mi", "prod-mi"})
    public ManagedIdentityCredential managedIdentityCredentialTest() {

        return new ManagedIdentityCredentialBuilder()
                .clientId(applicationClientId)
                .build();
    }

    public String getApplicationClientId() {
        return applicationClientId;
    }

    public void setApplicationClientId(String applicationClientId) {
        this.applicationClientId = applicationClientId;
    }

    public void setLoadDemoData(String loadDemoData) {
        this.loadDemoData = loadDemoData;
    }

    public boolean getLoadDemoData() {
        return loadDemoData != null && loadDemoData.toLowerCase().trim().equals("true");
    }
}