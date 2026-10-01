package com.amazon.sample.ui.config.chat;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.RETURNS_SELF;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.ai.bedrock.converse.BedrockChatOptions;
import org.springframework.ai.bedrock.converse.BedrockProxyChatModel;
import software.amazon.awssdk.regions.Region;

class BedrockChatConfigTest {

  @Test
  void createsClientWithConfiguredBedrockOptionsAndRegion() {
    var properties = new ChatProperties();
    properties.setModel("anthropic.claude-3-haiku-20240307-v1:0");
    properties.setMaxTokens(512);
    properties.setTemperature(0.25);
    var bedrockProperties = new BedrockChatProperties();
    bedrockProperties.setRegion("us-east-1");

    // Stub the provider boundary so this test needs no AWS credentials or network.
    var builder = mock(BedrockProxyChatModel.Builder.class, RETURNS_SELF);
    var model = mock(BedrockProxyChatModel.class);
    when(builder.build()).thenReturn(model);

    try (var factory = mockStatic(BedrockProxyChatModel.class)) {
      factory.when(BedrockProxyChatModel::builder).thenReturn(builder);

      var client = new BedrockChatConfig().chatClient(properties, bedrockProperties);

      assertThat(client).isNotNull();
      var options = ArgumentCaptor.forClass(BedrockChatOptions.class);
      verify(builder).defaultOptions(options.capture());
      assertThat(options.getValue().getModel()).isEqualTo(properties.getModel());
      assertThat(options.getValue().getMaxTokens()).isEqualTo(512);
      assertThat(options.getValue().getTemperature()).isEqualTo(0.25);
      verify(builder).region(Region.US_EAST_1);
      verify(builder).build();
    }
  }
}
