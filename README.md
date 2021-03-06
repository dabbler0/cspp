# A JavaScript interpreter for the CSP exam language

A tiny interpreter for the langauge defined on the exam reference sheet for the Computer Science Principles AP test. Documentation for this language is available [from CollegeBoard](https://secure-media.collegeboard.org/digitalServices/pdf/ap/ap-computer-science-principles-course-and-exam-description.pdf) pp 114-120.

Dependencies: `nodejs`, `npm`, `npm install -g coffee-script`.

Install:
```
npm install
```

Usage:
```
./main.coffee example_program.cspp
```

This project has two aims:
  - to define a usable antlr4 grammar for a [Droplet](https://github.com/droplet-editor/droplet) mode for the CSP exam language
  - to make CSP exam language runnable, ideally with broad tracing and debugging capabilites, for CSP AP students.
