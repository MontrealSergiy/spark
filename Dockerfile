FROM simexp/niak-cog:1.0.1


#author
LABEL maintainer="S.Boroday, MNI"

#metatdata

LABEL version="0.1"

LABEL description="First attempt to dockerize spark"


COPY  .  /spark

ENV PATH="/spark:${PATH}"

RUN chmod +x -R /spark
