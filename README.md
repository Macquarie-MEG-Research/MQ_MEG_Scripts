# Macquarie MEG Reseach group script Hub

Hub for the various MEG scripts used for processing and analysis

## Usage

This repository contains scripts that can be used for various tasks such as analysis or processing of MEG data.
Each script is also designed to have some information written about it by the author so that others who want to use it can read about it and learn how to use the script.
All the information for the various scripts can be found [here](https://macquarie-meg-research.github.io/MQ_MEG_Scripts/).

## Contributing

If you have a script you wish to store on the repository so that others may use it or contribute to it, you can fork the repository and make a PR with any changes made.
For automatic creation of documentation all that is required is a file named `info.md` in the same folder as the script.
This file is similar to a normal text file however it supports [markdown](https://daringfireball.net/projects/markdown/syntax) which allows you to format your document in a more visually appealing way than a simple text document.
The previous link as well as [this one](https://guides.github.com/features/mastering-markdown/) are great to see how to write markdown.

The documentation is automatically built when any changes are merged into the `master` branch on GitHub.
To see how the documentation will look before making a PR (or while fixing errors) you can follow these steps:

1. Open a command line interface in the root directory of the `MQ_MEG_Scripts` repository. This folder should contain the file `generate_docs.py`.
2. Install `mkdocs` for python using `pip install mkdocs`.
3. Generate the documentation table using `python generate_docs.py`.
4. Generate the documentation using mkdocs using `mkdocs serve`.
5. You can now see the documentation in real time by going to `127.0.0.1:8000` on your internet browser. Any changes to any `.md` files will be reflected immediately.

Remember, every time you add a new `.md` file somewhere, you will need to re-run `python generate_docs.py` to re-generate the `mkdocs.yml` file required to draw the entire site.
