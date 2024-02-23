# Wanna Chat - A Flutter / Dart chat app, using LangChain

![Wanna chat](/frontend/assets/banner.png)

This is a small demo project that implements LLM-based chat functionality, augmented with real data (also known as [RAG](https://blogs.nvidia.com/blog/what-is-retrieval-augmented-generation/)), to give more factually correct answers. The defalut implementation uses data about [Domain Driven Design](https://en.wikipedia.org/wiki/Domain-driven_design), in the form of text, video transcripts and various articles on the web.

This projects consists of two parts: a `Dart` based chat backend and a frontend app written in `Flutter` & `Dart`. 

## Backend (Dart "LLM app")
A simple **LLM app** that implements **RAG** functionality, using the framework **[LangChain.dart](https://langchaindart.com)**.

The backend provides a simple REST api, exposing three endpoints:
* /question
* /restore_conversation 
* /clear_conversation

To keep the backend as simple and lightweight as possible it was build using **[Dart Frog](https://dartfrog.vgv.dev)**. More complex real-world applications might consider using something like [ServerPod](https://serverpod.dev).


## Frontend (Flutter app)

A simple Flutter app implementing a basic chat interface, with history. The [ResultNotifier](https://pub.dev/packages/result_notifier) package is used for 
state management and more.
