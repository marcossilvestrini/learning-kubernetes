<h1><a name="readme-top"></a></h1>

[![PSScriptAnalyzer](https://github.com/marcossilvestrini/learning-kubernetes/actions/workflows/powershell.yml/badge.svg)](https://github.com/marcossilvestrini/learning-kubernetes/actions/workflows/powershell.yml)
[![Release](https://github.com/marcossilvestrini/learning-kubernetes/actions/workflows/release.yml/badge.svg)](https://github.com/marcossilvestrini/learning-kubernetes/actions/workflows/release.yml)
[![Check kubernetes App](https://github.com/marcossilvestrini/learning-kubernetes/actions/workflows/check-kubernetes-app.yml/badge.svg)](https://github.com/marcossilvestrini/learning-kubernetes/actions/workflows/check-kubernetes-app.yml)

[![MIT License][license-shield]][license-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Contributors][contributors-shield]][contributors-url]
[![Issues][issues-shield]][issues-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

# LEARNING KUBERNETES

![kubernetes](images/kubernetes.jpg)

<p align="center">
<strong>Explore the docs »</strong></a><br />
    <a href="https://marcossilvestrini.github.io/learning-kubernetes/">Main Page</a>
    -
    <a href="https://github.com/marcossilvestrini/learning-kubernetes">Code Page</a>
    -
    <a href="https://github.com/marcossilvestrini/learning-kubernetes/issues">Report Bug</a>
    -
    <a href="https://github.com/marcossilvestrini/learning-kubernetes/issues">Request Feature</a>
</p>

## Summary

<details>
  <summary><b>TABLE OF CONTENT</b></summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details><br>

<a name="about-the-project"></a>

## About Project

>This project aims to help students or professionals to learn the main concepts of kubernetes

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<a name="getting-started"></a>

## Getting Started

This is an example of how you may give instructions on setting up your project locally.
To get a local copy up and running follow these simple example steps.

<a name="prerequisites"></a>

### Prerequisites

This is an example of how to list things you need to use the software
and how to install them.

* git
* Virtual Box and extension
* Vagrant

<a name="installation"></a>

### Installation

#### Clone repository

```sh
git clone https://github.com/marcossilvestrini/learning-kubernetes.git
```

#### Set ssh keys in security folder

```sh
# generate ssh key pair for your user access hosts
ssh-keygen -q -t ecdsa -b 521 -N '' -f ~/.ssh/id_ecdsa <<<y >/dev/null 2>&1
cp ~/.ssh/id_ecdsa.pub security/

# generate ssh key pair for rancher
ssh-keygen -q -t ecdsa -b 521 -N '' -f security/rancher-key-ecdsa <<<y >/dev/null 2>&1
```

#### Set network

Set network configuration in Vagrantfile.
Example:

```sh
# NETWORK
    ol9_server01.vm.network "public_network", nic_type: "virtio", mac: "080027f3066a", ip: "192.168.0.130", netmask: "255.255.255.0", mode: "bridge",bridge: [
      "Intel(R) I211 Gigabit Network Connection",
      "MediaTek Wi-Fi 6 MT7921 Wireless LAN"
    ]    
```

#### Up kubernetes cluster

```sh
cd learning-kubernetes/vagrant/linux
vagrant up
```

<a name="usage"></a>

## Usage

Use this repository for get learning about kubernetes exam

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<a name="roadmap"></a>

## Roadmap

* [x] Create repository
* [x] Create github action for automation tasks
* [ ] Install kubernetes cluster

<p align="right">(<a href="#roadmap">back to roadmap</a>)</p>
<p align="right">(<a href="#readme-top">back to top</a>)</p>

>kubernetes Engine work with namespaces(PID,NET,IPC,MNT,UTS) and cgroups.

Kubernetes ports

![kubernetes control plane ports](images/kubernetes-cp-ports.jpg)

![kubernetes works ports](images/kubernetes-wk-ports.jpg)

Font: <https://livro.descomplicandokubernetes.com.br/pt/day_one/>

## Install kubernetes

<a name="kubernetes-install"></a>

```sh
foo
```

<p align="right">(<a href="#kubernetes-secrets">back to install kubernetes</a>)</p>
<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contributing

Contributions are what make the open source community such an amazing place to
learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and
create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

* This project is licensed under the MIT License * see the LICENSE.md file for details

## Contact

Marcos Silvestrini - marcos.silvestrini@gmail.com \
[![Twitter](https://img.shields.io/twitter/url/https/twitter.com/mrsilvestrini.svg?style=social&label=Follow%20%40mrsilvestrini)](https://twitter.com/mrsilvestrini)

Project Link: [https://github.com/marcossilvestrini/learning-kubernetes](https://github.com/marcossilvestrini/learning-kubernetes)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Acknowledgments

* [CNCF - Cloud Native Computing Foundation](https://www.cncf.io/)
* [OCI - Open Container Initiative](https://opencontainers.org/)
* [Borg](https://kubernetes.io/blog/2015/04/borg-predecessor-to-kubernetes/)
* [kubernetes Website](https://kubernetes.io/)
* [Github](https://github.com/kubernetes/kubernetes/)
* [Issues](https://github.com/kubernetes/kubernetes/issues)
* [CKA Certification](https://www.cncf.io/certification/cka/)
* [CKAD Certification](https://www.cncf.io/certification/ckad/)
* [CKS Certification](https://www.cncf.io/certification/cks/)
* [Book Linuxips](https://livro.descomplicandokubernetes.com.br/pt/)
* [Kind](https://kind.sigs.k8s.io/docs/user/quick-start)
* [Minikube](https://github.com/kubernetes/minikube)
* [k0s](https://k0sproject.io/)
* [k3s](https://k3s.io/)
* [RKE2](https://docs.rke2.io/architecture)
* [Up RKE2 Cluster HA](https://computingforgeeks.com/deploy-kubernetes-on-rocky-using-rke2/?expand_article=1)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES-->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/marcossilvestrini/learning-kubernetes.svg?style=for-the-badge
[contributors-url]: https://github.com/marcossilvestrini/learning-kubernetes/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/marcossilvestrini/learning-kubernetes.svg?style=for-the-badge
[forks-url]: https://github.com/marcossilvestrini/learning-kubernetes/network/members
[stars-shield]: https://img.shields.io/github/stars/marcossilvestrini/learning-kubernetes.svg?style=for-the-badge
[stars-url]: https://github.com/marcossilvestrini/learning-kubernetes/stargazers
[issues-shield]: https://img.shields.io/github/issues/marcossilvestrini/learning-kubernetes.svg?style=for-the-badge
[issues-url]: https://github.com/marcossilvestrini/learning-kubernetes/issues
[license-shield]: https://img.shields.io/github/license/marcossilvestrini/learning-kubernetes.svg?style=for-the-badge
[license-url]: https://github.com/marcossilvestrini/learning-kubernetes/blob/master/LICENSE
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/marcossilvestrini
