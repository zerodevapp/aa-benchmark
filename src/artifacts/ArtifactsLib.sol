// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

struct DeployArtifact {
    bytes initCode;
    address addr;
}

address constant DEPLOY_PROXY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

library ArtifactsLib {
    function deploy(DeployArtifact memory _artifact) internal returns (address) {
        (bool success,) = DEPLOY_PROXY.call(_artifact.initCode);
        require(_artifact.addr.code.length > 0, "Failed to deploy, check address");
        return _artifact.addr;
    }
}
