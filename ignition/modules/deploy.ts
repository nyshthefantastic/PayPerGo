import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("ContentRegistryModule", (m) => {
  const ContentRegistry = m.contract("ContentRegistry");

  return { ContentRegistry };
});