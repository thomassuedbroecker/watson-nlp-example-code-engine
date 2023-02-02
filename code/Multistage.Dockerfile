# Using the Docker container image for model

ARG WATSON_RUNTIME_BASE="cp.icr.io/cp/ai/watson-nlp-runtime:1.0.20"
ARG MODEL_1="cp.icr.io/cp/ai/watson-nlp_sentiment_aggregated-cnn-workflow_lang_en_stock:1.0.6"
ARG MODEL_2="cp.icr.io/cp/ai/watson-nlp_classification_ensemble-workflow_lang_en_tone-stock:1.0.6"

# ****************************
# BUILD: Prepare and unpacked models inside a container
# ****************************
FROM ${MODEL_1} as model1
RUN ./unpack_model.sh

FROM ${MODEL_2} as model2
RUN ./unpack_model.sh

# ****************************
# PRODUCTION: Runtime with unpacked models
# ****************************
FROM ${WATSON_RUNTIME_BASE} as release

RUN true && \
    mkdir -p /app/models

ENV LOCAL_MODELS_DIR=/app/models
COPY --from=model1 app/models /app/models
COPY --from=model2 app/models /app/models
