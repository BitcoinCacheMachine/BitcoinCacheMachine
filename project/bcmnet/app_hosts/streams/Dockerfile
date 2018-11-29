FROM microsoft/dotnet:2.1-sdk AS base

WORKDIR /app/streamsapp
COPY ./streamsapp/* ./

RUN dotnet restore

RUN dotnet add package -v 0.11.4 Confluent.Kafka

RUN dotnet build

ENTRYPOINT ["dotnet", "streamsapp.dll"]

# RUN dotnet build -c Release -o /app/streamsapp

# FROM builder AS publish
# RUN dotnet publish -c Release -o /app/streamsapp


# FROM base AS production
# WORKDIR /app
# COPY --from=publish /app .
# ENTRYPOINT ["dotnet", "Web.dll"]