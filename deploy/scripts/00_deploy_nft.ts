import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment): Promise<void> {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log("[LOG] - deployer", deployer);

  // contarct address = 0x9fE5124F201F6197b2C1cD171aBdC48a5547E65a

  await deploy("NFT", {
    from: deployer,
    proxy: {
      owner: deployer,
      proxyContract: "OptimizedTransparentProxy",
      execute: {
        init: {
          methodName: "initialize",
          args: ["My NFT", "NFT"],
        },
      },
    },
    log: true,
  });
};

func.tags = ["NFT"];
export default func;
