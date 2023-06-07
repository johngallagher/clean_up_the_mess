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

[^8]

We've removed a lot of the duplication.

You'll see that a pattern is emerging.

Instead of resisting the pattern, we're embracing it.

Try to make things look alike. Try to make them rhyme.

This is still duplication but it's less obvious right now how to get rid of it.

The pattern is still pronounced - when someone is a high risk we always want to block them.

What happens after that depends on the controller.

When the person is medium risk, they're always challenged.

Interesting that this *always* happens.

Let's leave this duplication for now.

At least it's symmetrical so we can see which bits are the same and which are different.

[^9]

We can see lots of duplication in this file.

Let's clean it up.

That was an easy piece of cleanup.

So far so good.

We're going to leave it there for now for removing duplication.

The biggest smell is the duplication of ideas around [^8].

I don't know what to do about this yet.

So I'm not going to force anything.

Tip: a common mistake is to force removing duplication.

I find myself waiting for the duplication to reveal a pattern.

Once the pattern has been revealed, it's a matter of waiting for the right moment.

This is too early. I don't have enough feedback from the changing requirements to know what will happen.

I could push extra methods into `Protectable` but this feels "artifical" - like we're doing it for the sake of it.

Tip: When removing duplication think:

* Will this introduce a new abstraction?
* Will this abstraction be useful?
* Is this an "artifical" refactor - what I call "shovelling around the shit"?
* How to know? This comes with experience but it's a red flag if you're just pushing everything into more and more methods that don't improve the design.

## 4. No dead code

I've looked around and can't see any code we're not using.

So let's move on.

Note: I haven't gone through this exercise with the tests... yet.

In this book I've got to pick my battles, so I'll leave refactoring the tests as an exercise for you.

Let's move onto the next requirement.

## Change 2: Use policies instead of risk levels for Castle

OK. So we've got a problem with this way of doing things.

The app decides when to block or challenge.

Instead, we want castle to tell us when to block or challenge.

That's because we want to create rules in Castle to determine when to block or challenge.

This way our system is a lot more flexible! It means our code doesn't have to change all the time for exceptions.

Let's start by changing the tests to establish this new behaviour.

[^10]

Recap.

We moved in very small steps.

Every step was measured and designed to keep as many tests passing as possible.

We did have one failing test for a little while, but even that could have been avoided.

This is what allows big refactorings!

We also kept the interface from the old code exactly the same.

We just created a *new* method that returned a *new* interface.

Then we swapped it out and in one small commit all the tests pass and we're good.

This is what good design looks like. You're minimising the things that change.

Any time lots of tests break, it's telling you something.

[^11]

We've replaced our risk level with policy.

This was pretty quick - it took about 15 minutes.

That's because we'd encapsulated all the logic. It was nice and neat.

Next step - get rid of the likelihood arguments in the test.

[^12]

We've now swapped out microposts to use policies too.

This took all of 5 minutes. The pattern has been established.

[^13]

We want to remove the duplication. So first we program by intent.

What's the interface we wish we had?

We don't want to continually be asking questions.

We also *always* want to block and challenge when a policy says so.

If we keep this duplication, there's a chance we might forget to do that one day.

That makes things fragile.

So instead, we should just build that functionality once.

Then we can pass back control of the program using `#on_deny` and `#on_challenge`

This gives us a nice mechanism for the controller to decide what to do.

This is dependency inversion.

It's about giving control back to the caller when it matters.

## Change 3: Change to using AWS for firewall blocking and fraud detection

Now let's attempt a bigger change.

Let's say Castle is getting too expensive.

There's another driver though - the organisation has grown a lot. 

They've decided to move onto AWS for the majority of their IT infrastructure.

Castle is still one of the apps that we need to provide our staff with a special login for.

AWS has a fraud detection API.

We'd like to use it instead of Castle.

The normal way of approaching this - change the code in every method in `Protectable` until it works with AWS.

We could actually do this.

We've encapsulated the "what" behind methods.

And the controllers don't need to know how it works.

The weaknesses of "change the code to make it work":

1. Tests will break and remain broken for a while
2. The "blast radius" of changes will be wide, leading to large PRs
3. The risk we'll miss something is increased, because we're changing a lot all at once

We can do better.

Whenever it comes to a big change like this, go through the code line by line and label it with the concern.

What's a concern?

... examples here ...

OK, so let's do this for `Protectable`.

We want to see which areas are related to Castle. That'll give us an idea of which bits we need to swap out.

If you do this process for the controllers, you'll see they're totally isolated from anything related to Castle.

Note I've deleted some dead code.

Now we've done that, we can see there are two methods that related entirely to Castle.

This is great news. We've cleanly isolated these parts from everything else.

Sure, all these concerns are in one file, which isn't great.

But they're pretty self contained. I've seen instances where the concerns are spread out between 10 different methods.

```
Tip: keep concerns encapsulated in as few methods as possible
```

Next step - I can see some pretty easy tidy up here.

There are some methods that can be compressed together in a way that doesn't hurt our concerns very much.

[^14]

Let's go through the four rules again.

1. Works
2. Good names
3. Remove duplication
4. No dead code

Let's improve the names. The hacker_likelihood isn't a good name now.

```
Tip: constantly be looking for better names. Names are the single biggest driver of better design.
```

Let's go with `evaluate_policy`.

And since this has `policy` in the name, we can return a policy.

We can do this because nothing else depends on the `RiskPolicy` class. Nice.

That's the benefit of loose coupling. We can move things around.

Why am I moving `RiskPolicy` into that method?

What were we returning before? A response.

That response is **coupled to Castle**. It was structured in the way Castle wants to structure it.

But that tiny bit of knowledge is leaking out into the rest of the method.

We're going to swap out Castle for AWS Fraud Detection.

So we need a higher level concept at this interface. And once again, the names communicate what that higher level concept is.

It's a **policy**.

This is super cool, because it moves us *away* from the specific nuts and bolts and details of Castle.

It abstracts these details away by giving us a concept that **any** fraud detection system can understand and return - a policy.

```
Tip: when swapping out behaviour, focus on the interface between the pieces. Make sure the interface is talking at a high enough level and you'll be isolated from the specific mechanisms.
```

So to recap:

-> evaluate_policy
<- policy

Makes sense!

Test - can you imagine a different fraud detection service giving back a response shaped with a `:policy` key at the root?

Hmmm. Maybe not. It'd depend on the imlementation.

Look at what comes back from AWS:

```json
{
   "externalModelOutputs": [ 
      { 
         "externalModel": { 
            "modelEndpoint": "string",
            "modelSource": "string"
         },
         "outputs": { 
            "string" : "string" 
         }
      }
   ],
   "modelScores": [ 
      { 
         "modelVersion": { 
            "arn": "string",
            "modelId": "string",
            "modelType": "string",
            "modelVersionNumber": "string"
         },
         "scores": { 
            "string" : 578
         }
      }
   ],
   "ruleResults": [ 
      { 
         "outcomes": ["deny"],
         "ruleId": "rule_id"
      }
   ]
}
```

Does this look remotely like the Castle response?

```json
{
  "policy": "deny",
  "risk": 0.9
}

Nope.

But can you imagine a fraud detection service being able to return a policy? Sure!

It's a **shared language** within the domain.

We want objects to be swappable for different behaviours.

This is the piece of OO design that took me 10 years to understand!

Understand this, and a world of opportunities open up to you.

[^15]

Now we push these methods into a class.

I see many engineers seeming afraid of creating classes.

My rule of thumb - if something is an unrelated concern, it's fine to split it out into a class.

Note - the timing of this is crucial. If we'd done this much sooner than now, we'd have ended up with a poor abstraction.

But now is the right time - we've completed the feature, and the code is neatly encapsulated in two places.

[^16]

Extracting these into a class also had another beneficial effect.

It turns out there were some hidden dependencies.

This is partly why I'm not keen on concerns - they hide all sorts of sneaky coupling that rears it's ugly head when you try to split it apart.

We've now split those things out to live in method arguments.

Turns out adding `request` was good enough.

I will say that four method arguments is quite a lot. But we'll tackle that later.

Another design weakness - now that it's split out, we can see that the `$registration` string that has a special meaning in Castle is leaking out into the main methods.

That's a problem. Not a big one, we can abstract it away.

Let's do that now.

[^18]

As usual with evolutionary design, we end up somewhere I didn't expect.

You can see we replaced the different arguments for events with one concise one - registration.attempted for example.

Then in [^19] you can see all the Castle specific strings are, once again, encapsulated inside the Castle object.

Note that, once again, we're going way more generic in the calling code and more Castle specific.

Separating out the "what" from the "how" once again. Reducing coupling.

A few unintended consequences showing us that this is moving in the right direction:

1. All Castle events are neatly listed out inside the castle class. Great for documentation!
2. The calling code becomes more compact
3. The calling code is more readable -  event: 'login.succeeded' - got it! gives us options and is way better a name than "type" and "status" - what do they even mean? An event is something anyone can understand.
4. We've introduced a new idea to the domain - an "event" name. Which could turn into an "event" object? Maybe.
5. A pattern is emerging. You can see how all these methods are taking the same shape.

Let's go one step further and remove some more duplication.


[^20]

Cautiously, let's swap this out small piece at a time.

First microposts. Tests pass. Great!

And now, as if by magic, we can get rid of these methods.

Wow. Duplication begone! Look how much cleaner this looks.

I'll be honest - this is why I'm still obsessed with this game after 10 years.

Look at how nicely this cleans things up.

No more clumsy methods with duplication.

Next job - we need to refactor the tests.

When we swap out Castle for AWS, these tests will all break.

Let's encapsulate this behaviour too.



### Act 2A - The Normal Way

* "Hack in" each of these changes in the simplest way possible.
* Very little abstraction.
* Typical code I see in projects
* "Shovel the shit" around

### Act 2B - The Designed Way

* Use objects to abstract behaviour away
* Assess coupling and concern metrics using techniques
* Tidy first, then change behaviour

## Design principles

* Coupling
* Cohesion
* Modularity

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
