FROM salesforce/salesforcedx

# Update SFDX CLI to the latest version
RUN sfdx update

# Install lwc-dev-server
RUN sfdx plugins:install @salesforce/lwc-dev-server

# Update plugins
RUN sfdx plugins:update

# Install the Prettier plugin for Apex
RUN npm install --global prettier prettier-plugin-apex

# Install the sfdx-lwc-jest
RUN npm install --global @salesforce/sfdx-lwc-jest

# Install PMD
ENV PMD_VERSION "6.24.0"
ENV PMD_DIR "/bin/pmd/"
RUN mkdir -p "${PMD_DIR}" \
    && wget -P /tmp/ https://github.com/pmd/pmd/releases/download/pmd_releases%2F${PMD_VERSION}/pmd-bin-${PMD_VERSION}.zip \
    && unzip /tmp/pmd-bin-${PMD_VERSION}.zip -d /tmp \
    && rm /tmp/pmd-bin-${PMD_VERSION}.zip \
    && mv /tmp/pmd-bin-${PMD_VERSION}/* ${PMD_DIR}