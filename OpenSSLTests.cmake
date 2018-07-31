include(CheckCSourceCompiles)
include(CheckCXXSourceCompiles)
include(CheckCSourceRuns)

set(CMAKE_REQUIRED_LIBRARIES ${OPENSSL_LIBRARIES} "-ldl")
# Use all includes, not just OpenSSL includes to see if there are
# include files of different versions that do not match
GET_DIRECTORY_PROPERTY(includes INCLUDE_DIRECTORIES)
set(CMAKE_REQUIRED_INCLUDES ${includes})

check_c_source_compiles("
    #include <openssl/ssl.h>
    int main() { return 0; }
" including_ssl_h_works)

if (NOT including_ssl_h_works)
    # On Red Hat we may need to include Kerberos header.
    set(CMAKE_REQUIRED_INCLUDES ${includes} /usr/kerberos/include)
    check_c_source_compiles("
        #include <krb5.h>
        #include <openssl/ssl.h>
        int main() { return 0; }
    " NEED_KRB5_H)
    if (NOT NEED_KRB5_H)
        message(FATAL_ERROR
            "OpenSSL test failure.  See CmakeError.log for details.")
    else ()
        message(STATUS "OpenSSL requires Kerberos header")
        include_directories("/usr/kerberos/include")
    endif ()
endif ()

if (OPENSSL_VERSION VERSION_LESS "0.9.7")
    message(FATAL_ERROR "OpenSSL >= v0.9.7 required")
endif ()

check_cxx_source_compiles("
#include <openssl/x509.h>
    int main() {
        const unsigned char** cpp = 0;
        X509** x =0;
        d2i_X509(x, cpp, 0);
        return 0;
    }
" OPENSSL_D2I_X509_USES_CONST_CHAR)

if (NOT OPENSSL_D2I_X509_USES_CONST_CHAR)
    # double check that it compiles without const
    check_cxx_source_compiles("
        #include <openssl/x509.h>
        int main() {
            unsigned char** cpp = 0;
            X509** x =0;
            d2i_X509(x, cpp, 0);
            return 0;
        }
        " OPENSSL_D2I_X509_USES_CHAR)
    if (NOT OPENSSL_D2I_X509_USES_CHAR)
        message(FATAL_ERROR
            "Can't determine if openssl_d2i_x509() takes const char parameter")
    endif ()
endif ()

if (NOT CMAKE_CROSSCOMPILING)
    check_c_source_runs("
        #include <stdio.h>
        #include <openssl/opensslv.h>
        #include <openssl/crypto.h>
        int main() {
            printf(\"-- OpenSSL Library version: %s\\\\n\", SSLeay_version(SSLEAY_VERSION));
            printf(\"-- OpenSSL Header version: %s\\\\n\", OPENSSL_VERSION_TEXT);
            if (SSLeay() == OPENSSL_VERSION_NUMBER) {
                return 0;
            }
            return -1;
        }
    " OPENSSL_CORRECT_VERSION_NUMBER )

    if (NOT OPENSSL_CORRECT_VERSION_NUMBER)
        message(FATAL_ERROR
            "OpenSSL library version does not match headers")
    endif ()
endif ()

set(CMAKE_REQUIRED_INCLUDES)
set(CMAKE_REQUIRED_LIBRARIES)
