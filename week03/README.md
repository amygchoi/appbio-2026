# Week 3 Assignment 

For this week's assignment I forked [Victoria's repository](https://github.com/VAbramRepo/appbio-2026).
My forked repository can be found [here](https://github.com/amygchoi/appbio2026-week3/tree/main).

Before running any file in their repository, I ran two commands:
```
ls
```
```
find . -maxdepth 2 -type f
```

output (respectively):
```
README.md  README.txt week01     week02
```
```
./week01/README.md
./README.md
./week02/Makefile
./week02/README.md
./README.txt
./.git/config
./.git/HEAD
./.git/description
./.git/index
./.git/packed-refs
```
I reviewed the files in the repository and found no suspicious files. Based on the repository structure, there were no files that appeared potentially dangerous, but I asked AI to review ```Makefile```.


## Makefile

I used the following prompt to review Makefile before running  ```make```:

```Makefile```
> Review this Makefile for potentially dangerous behavior before I run it. Examine every command and identify anything that could delete or overwrite files, access files outside the repository, require administrator privileges, change system settings or permissions, expose credentials, upload local data, download files from untrusted sources, execute downloaded code, or consume excessive computational resources. For each potentially risky command, explain what it does and classify it as safe, questionable, or dangerous in this context. Clearly distinguish actual problems from theoretical risks. Do not execute the Makefile.

This request was routed to GPT-5.6 Luna. The output was:
```
Overall assessment: With the default variables, this Makefile does not request administrator privileges, change permissions/system settings, expose credentials, upload local data, or execute downloaded programs. The main real risks are recursive deletion in clean, overwriting generated files, and trusting/extracting downloaded archive contents.
```

The Makefile did not appear to contain any unexpected or highly dangerous commands. Although the `clean` target uses `rm -rf`, it is limited to the generated output directories.



## README.md

The ```README.md``` is organized into clear sections for genome information, IGV observations, and Makefile usage and explains the purpose of the project, the selected genome, and the main Makefile targets. The screenshots support the observations and make the analysis easier to follow. It provides an example command, but reproducibility could be improved by listing the required software and identifying the exact output files. 

I ran ```make download-genome``` and confirmed that it downloaded the FASTA, GFF, and GTF files into their designated directories. I also ran ```make igv-index```, which successfully generated the ```.fai``` index and the compressed and indexed GFF files. Therefore, the code generally produced the results described in the README.


## Asking AI to compare my solution to theirs

I asked ```GPT-5.6 Sol```, using the following prompt:
> Compare the following two README files in terms of reproducibility, readability, and structure. 
>
> For each README:
> - Briefly explain the strengths and weaknesses.
> - Point out specific issues or missing information that affect reproducibility or usability.
> - Base your evaluation only on what is actually provided in the README; do not assume missing information exists elsewhere. 
>
> Then provide a comparison table with the three scores, which README is better overall and why, and the 3 most important improvements for the weaker README. Be critical and evidence-based rather than simply preferring one README.


### My findings:


Victoria's ```README.md``` has a clear overall structure and includes the NCBI accession, source link, Makefile targets, selected genomic coordinate, and IGV screenshots. These elements make the purpose and general workflow easy to understand. Its reproducibility could be improved by listing the required software, specifying the working directory and output paths, and providing clearer instructions for indexing and loading the files into IGV. My ```README.md``` provides more detailed support for its results through direct download links, commands, outputs, file locations, annotation counts, and gene-spacing measurements. This makes most of its command-line analysis easier to reproduce. It could still be improved by adding a required-software section, explaining how to load the custom files into IGV, and shortening the Makefile-generation prompt. Overall, according to ChatGPT, mine provides more complete reproducibility information, while the other one offers a useful overview that would benefit from a few additional details and corrections.


Link to the pull request: https://github.com/VAbramRepo/appbio-2026/pull/1