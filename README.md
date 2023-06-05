# Clean Up The Mess - Example App

Structure of this exercise

Act 1

* Sets up the story
* Introduce characters
* Create relationships
* Establish hero's unfulfilled desire

Act 2

* Dramatic action
* Held together by confrontation
* Hero encounters obstacles which prevent them achieving their desire

Act 3

* Resolves the story
* Solution - did the character succeed or fail?


# Act 1

What do we want?

Protect our app from hackers.

What have we got?

* Rails app
* Creating microposts
* Calls out to Castle
* Detects hackers and presents them with 500 errors
* Code is messy

## Rules for hackers

* Anyone above a risk level of 0.8 is a suspected hacker

## Rules for Cloudflare

* Signing up - hackers are challenged
* Logging in - hackers are blocked
* Microposts - hackers are challenged

# Act 2

* A series of changes
* We'll see how the design responds to these changes

## Change 1: Challenge and block more consistently

* For anyone between 0.6 and 0.8 they're challenged on everything
* For anyone greater than 0.8 they're blocked on everything

## Refactor

Let's assess the code we have against design principles.

Let's use the four rules of simple design.

1. Works - yes. We have reasonable coverage and the tests pass.
2. Good names
3. No duplication
4. No dead code

## 2. Good names

First, sessions controller.

[^1]

`type` and `status` are what we pass to Castle, but they're not very revealing as names.

We're logging in, so let's make that in the name.

Names should be drop dead simple. 

Tip: Say what the methods doing (not HOW it's doing it remember) to a pair partner or yourself.

Try to use plain english. Explain it as if to your Mum or a non technical friend.

Imagine trying to understand the name when you're high, drunk, stoned or very tired.

[^2]

Any time you're comparing numbers, it's time to take a step back.

0.6? 0.8? What do these risk levels mean?

It's not clear. There's no names.

This is a design smell called "primitive obssesion".

There's a good name hiding here.

What is it? It's a score. So a score can be low, medium or high.

And we do different things for low medium and high.

[^3]

By naming the score and naming query methods on it, we've had to create an object.

This is a pattern you'll see repeatedly.

There was a missing concept in the code.

It's a concept that was there in a number, but the number on it's own wasn't meaningful enough.

It needed meaning wrapped around the numbers.

@design_principle:abstraction 
@design_principle:encapsulation 

Abstraction - giving something a higher level name.

Encapsulation - wrapping up details.

When you focus on names, it leads you to create more objects.

Those objects are new abstractions. And they encapsulate details.

Once again, we're focusing on the "what" not the "how".

The "what" is "are they low, medium or high risk?"

The "how" is the nitty gritty of which scores we choose. This is a detail. This is configuration.

One day we may decide to change what constitutes "low", "medium" or "high". When that day comes, we'll have one place to change it - `RiskScore`.

Next step - perform similar naming operations across other pieces of code.


### `UsersController`

[^4]

Repeat the same thing. Tweak the name of the method slightly.

The fact that we've not had to add much code is a great sign we're on the right path here.

It makes sense - our abstraction is the repeated logic of "if < 0.6" etc.

That said, we'll focus on duplication in a moment.

[^5]

Same thing repeated. Similar pattern.

## 3. No duplication

We could go further, but let's move onto duplication.

No duplication of code or ideas.

It's important not to go too far with this too soon.

That's why we've let this build up whilst we build the system.

Now let's tackle some duplication.

Start at sessions controller first.

See [^6] and [^7]? Those three lines are duplicated.

So let's get rid of them.

## 4. No dead code

## Design principles

Next, we'll assess:

* Coupling
* Cohesion
* Modularity



## Change 2: Use policies instead of risk levels for Castle



## Change 3: Change to using AWS for firewall blocking and fraud detection


### Act 2A - The Normal Way

* "Hack in" each of these changes in the simplest way possible.
* Very little abstraction.
* Typical code I see in projects
* "Shovel the shit" around

### Act 2B - The Designed Way

* Use objects to abstract behaviour away
* Assess coupling and concern metrics using techniques
* Tidy first, then change behaviour

## Act 2C - Comparison

* Use a diagram to compare the normal way with the designed way.
* Examine tradeoffs
* Compare and contrast the two approaches
* Sliding scale

# Act 3 - Conclusion

* I've introduced the principles to you
* Recap the techniques and principles
* The really hard part - judgement - is another book.
* Go forth and look for interfaces.
