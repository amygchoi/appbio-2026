# Week 1 Assignment

## Question 2
I am using VS Code.

## Question 6
To check the version of samtools, I used:
```bash
samtools --version
```
Output:
```
samtools 1.24
Using htslib 1.24
Copyright (C) 2026 Genome Research Ltd.
```

## Question 7
To check my current working directory, I used:
```bash
pwd
```
Output:
```
/Users/gqc5391/edu/appbio-2026/week01
```

I created a nested directory structure using:
```bash
mkdir -p nested/structure
```
This created:
```text
edu/
└── appbio-2026/
    └── week01/
        └── nested/
            └── structure/
```

## Question 8
I created files in different directories using:
```bash
touch nested/file1.txt
touch nested/structure/file2.txt
```
This created:
```text
week01/
└── nested/
    └── file1.txt
    └── structure/
        └── file2.txt
```

## Question 9 
I accessed 'file1.txt' using a relative path using:
```bash
cat nested/file1.txt
```

I accessed 'file2.txt' using a absolute path using:
```bash
cat /Users/gqc5391/edu/appbio-2026/week01/nested/structure/file2.txt
```