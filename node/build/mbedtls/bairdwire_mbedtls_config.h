/* A libdatachannel precisa de DTLS-SRTP, e o nó usa a lib a partir de várias threads. */
#define MBEDTLS_SSL_DTLS_SRTP
#define MBEDTLS_THREADING_C
#define MBEDTLS_THREADING_PTHREAD
