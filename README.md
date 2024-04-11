# Wanna Chat - A Flutter / Dart chat app, using LangChain

![Wanna chat](/frontend/assets/banner.png)

This is a small demo project that implements LLM-based chat functionality, augmented with real data (also known as [RAG](https://blogs.nvidia.com/blog/what-is-retrieval-augmented-generation/)), to give more factually correct answers. The defalut implementation uses data about [Domain Driven Design](https://en.wikipedia.org/wiki/Domain-driven_design), in the form of text, video transcripts and various articles on the web.

This projects consists of two parts: a `Dart` based chat backend and a frontend app written in `Flutter` & `Dart`. 

## Backend (Dart "LLM app")
A simple **LLM app** that implements **RAG** functionality, using the framework **[LangChain.dart](https://langchaindart.com)**.

The backend provides a simple REST api, exposing three endpoints:
* GET /chat/{sessionId} - Gets the chat history
* POST /chat/{sessionId} - Ask a questions
* DELETE //chat/{sessionId} - Clears the conversation

To keep the backend as simple and lightweight as possible it was build using **[Dart Frog](https://dartfrog.vgv.dev)**. More complex real-world applications might consider using something like [ServerPod](https://serverpod.dev).

### Running the backend server

* Set the `OPENAI_API_KEY` environment variable.
* Run the server locally using ```dart_frog dev```

See [backend/README.md](backend/README.md) for more details.

## Frontend (Flutter app)

A simple Flutter app implementing a basic chat interface, with history. The [ResultNotifier](https://pub.dev/packages/result_notifier) package is used for 
state management and more.

## Data

A set of default documents, on the subject of Domain-Driven Design, are included and uses as data for the RAG chain in the backend:

* DDD Reference by Eric Evans - https://www.domainlanguage.com/ddd/reference/
* Domain Driven Design Quickly - https://www.infoq.com/minibooks/domain-driven-design-quickly/
* The InfoQ eMag: Domain-Driven Design in Practice - https://www.infoq.com/minibooks/emag-domain-driven-design/
* Domain-Driven Design in Software Development: A Systematic Literature Review on Implementation, Challenges, and Effectiveness (Ozan Özkan, Önder Babur, Mark van den Brand) - https://arxiv.org/abs/2310.01905

