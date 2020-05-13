FROM microsoft/dotnet:2.1.500-sdk-alpine3.7 AS builder
WORKDIR /source

RUN apk update && apk add --no-cache  git 
RUN git clone https://github.com/dgarage/NBXplorer

RUN cd NBXplorer && dotnet restore && cd ..
RUN cd NBXplorer && \
    dotnet publish --output /app/ --configuration Release NBXplorer/NBXplorer.csproj

FROM microsoft/dotnet:2.1.6-aspnetcore-runtime-alpine3.7
WORKDIR /app

ENV NBXPLORER_DATADIR=/root/.nbxplorer
RUN mkdir $NBXPLORER_DATADIR
VOLUME $NBXPLORER_DATADIR

COPY --from=builder "/app" .
ENTRYPOINT ["dotnet", "NBXplorer.dll"]