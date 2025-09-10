ARG __alpine_version=3.22.0
FROM alpine:${__alpine_version}

# Alpine packages versions: https://pkgs.alpinelinux.org/
ARG __curl_version=8.14.1-r1
ARG __git_version=2.49.1-r0
ARG __mandoc_version=1.14.6-r13
ARG __openssh_version=10.0_p1-r7
ARG __shellcheck_version=0.10.0-r2
ARG __shunit2_version=2.1.8-r1

ARG __gid=888
ARG __gname=dev
ARG __uid=888
ARG __uname=dev
ARG __user_home=/home/${__uname}

RUN apk update --no-cache \
    && apk upgrade --no-cache \
    && apk add --no-cache \
      curl=${__curl_version} \
      git=${__git_version} \
      mandoc=${__mandoc_version} \
      openssh-client=${__openssh_version} \
      shellcheck=${__shellcheck_version} \
      shunit2=${__shunit2_version} \
    && addgroup -g ${__gid} ${__gname} \
    && adduser -u ${__uid} -G ${__gname} -D -h ${__user_home} ${__uname} \
    && mkdir "${__user_home}/o" "${__user_home}/.ssh" "${__user_home}/s" \
    && chown ${__uid}:${__gid} "${__user_home}/o" "${__user_home}/.ssh" "${__user_home}/s"

# minimal healthcheck, we do not really need it here
HEALTHCHECK CMD exit 0

USER ${__uname}

WORKDIR "${__user_home}"

VOLUME [ "${__user_home}/o", "${__user_home}/.ssh", "${__user_home}/s" ]
