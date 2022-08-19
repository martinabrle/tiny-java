package app.demo.todo.utils;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpResponse.BodyHandlers;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fasterxml.jackson.databind.ObjectMapper;

//How to debug:
// ...retrieve the token first:
//   token=$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true | awk -F"[{,\":}]" '{print $6}')
// ...retrieved the secret from the keyvault
//   curl -s "https://MY_KEYVAULT_NAME.vault.azure.net/secrets/APP-INSIGHTS-INSTRUMENTATION-KEY?api-version=2016-10-01" -H "Authorization: Bearer ${token}"

public class KeyVaultHelper {
    public static final Logger LOGGER = LoggerFactory.getLogger(KeyVaultHelper.class);

    private final static URI KV_TOKEN_ENDPOINT_URI = URI.create(
            "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net");
    private final static String KV_SECRET_URI_TEMPLATE = "https://%KEYVAULT_NAME%.vault.azure.net/secrets/%KEYVAULT_SECRET_NAME%?api-version=2016-10-01";

    public static String getSecret(String keyVaultName, String keyVaultSecretName, boolean debugAuthToken) {
        KeyVaultSecret secret = null;
        try {
            Token localToken = getLocalToken(debugAuthToken);

            if (localToken == null || localToken.getAccessToken() == null) {
                return null;
            }

            String kvSecretName = KV_SECRET_URI_TEMPLATE.replace("%KEYVAULT_SECRET_NAME%", keyVaultSecretName)
                    .replace("%KEYVAULT_NAME%", keyVaultName);

            HttpRequest httpRequest = HttpRequest.newBuilder()
                    .uri(URI.create(kvSecretName))
                    .setHeader("Content-Type", "application/json")
                    .setHeader("Authorization", localToken.getTokenType() + " " + localToken.getAccessToken())
                    .GET()
                    .build();

            HttpClient httpClient = HttpClient.newHttpClient();

            HttpResponse<String> httpResponse = httpClient.send(httpRequest, BodyHandlers.ofString());

            if (httpResponse.statusCode() != 200) {
                LOGGER.error(
                        String.format("Received HTTP Status '%d' as a response from the keyvault.",
                                httpResponse.statusCode()));
                return null;
            }
            
            ObjectMapper objMapper = new ObjectMapper();

            secret = objMapper.readValue(httpResponse.body(), KeyVaultSecret.class);
            
            if (secret == null) {
                return null;
            }
        } catch (Exception ex) {
            LOGGER.error(String.format("KeyVault secret retrieval request failed: (%s)", ex.getMessage()));
            return null;
        }

        return secret.getValue();
    }

    public static Token getLocalToken(boolean debugAuthToken) {

        Token token;

        try {
            HttpRequest httpRequest = HttpRequest.newBuilder()
                    .uri(KV_TOKEN_ENDPOINT_URI)
                    .setHeader("Content-Type", "application/json")
                    .setHeader("Metadata", "true")
                    .GET()
                    .build();

            HttpClient httpClient = HttpClient.newHttpClient();

            HttpResponse<String> httpResponse = httpClient.send(httpRequest, BodyHandlers.ofString());

            if (httpResponse.statusCode() != 200) {
                LOGGER.error(String.format("Received '%d' from the local identity endpoint.", httpResponse.statusCode()));
                return null;
            }
            String responseString = httpResponse.body();
            if (debugAuthToken) {
                LOGGER.debug(String.format("Received identity endpoint's response: %s", responseString));
            }

            ObjectMapper objMapper = new ObjectMapper();

            token = objMapper.readValue(httpResponse.body(), Token.class);

            if (debugAuthToken) {
                LOGGER.debug(String.format("Received token: %s", token));
            }

        } catch (Exception ex) {
            LOGGER.error(String.format("Token retrieval request failed (%s)", ex.getMessage()));
            return null;
        }

        return token;
    }
}
