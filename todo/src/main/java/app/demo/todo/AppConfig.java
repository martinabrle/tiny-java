package app.demo.todo;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

import com.azure.identity.AzureCliCredential;
import com.azure.identity.AzureCliCredentialBuilder;
import com.azure.identity.ManagedIdentityCredential;
import com.azure.identity.ManagedIdentityCredentialBuilder;

@Configuration
public class AppConfig {

    @Bean
    @Profile("local-mi")
    public AzureCliCredential azureCliCredential() {
        return new AzureCliCredentialBuilder().build();
    }

    @Bean
    @Profile("!local-mi")
    public ManagedIdentityCredential managedIdentityCredential() {
        return new ManagedIdentityCredentialBuilder()
                .clientId("f63574e7-c67d-4d6b-a4ea-78c55e4081c7")
                .build();
    }
}