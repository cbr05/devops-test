FROM alpine:3.19

RUN apk add --no-cache curl

COPY loadgen.sh /loadgen.sh
RUN chmod +x /loadgen.sh

CMD ["/loadgen.sh"]
