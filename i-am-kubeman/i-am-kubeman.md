# I Am Kubeman

I never thought I'd be going to Walmart for technology tools, advice, etc. However, thanks to Aymen EL Amri's great curated weekly email, Kaptain, on all things Kubernetes, see https://www.faun.dev/, I ran across a great tool from Walmart Labs called [Kubeman](https://github.com/walmartlabs/kubeman). If you are managing multiple Kubernetes clusters, and that's almost always the case if you're using Kubernetes, Kubeman is a tool you need to consider. In addition to making it easier to investigate issues across multiple Kubernetes clusters, it understands Istio as well.

## Install Kubeman

The easiest way to install Kubeman is with one of the pre-built binaries for Linux, Windows or Mac. You can find them at https://github.com/walmartlabs/kubeman/releases. The current release, 0.5, is their first public release.

## Kubernetes Contexts

In order to use Kubeman, you must first connect to your Kubernetes cluster using kubectl in order to save the context to your local kube config. Kubeman uses your local kube config to determine which cluster(s) will be available to you.

