import "commonReactions/all.dsl";

context 
{
    // declare input variables here
    input phone: string;

    // declare storage variables here 
    name: string = ""; 
    policy_number: string = ""; 
    policy_read: string = "";
    policy_status: string = "";
    rating: string = "";
    feedback: string = "";
    claim: string = "";
}

// declare external functions here 
external function check_policy(policy_number: string): string;
external function convert_policy(policy_number: string): string;

// lines 28-42 start node 
start node root 
{
    do //actions executed in this node 
    {
        #connectSafe($phone); // connecting to the phone number which is specified in index.js that it can also be in-terminal text chat
        #waitForSpeech(1000); // give the person a second to start speaking 
        #say("greeting"); // and greet them. Refer to phrasemap.json > "greeting"
        wait *; // wait for a response
    }
    transitions // specifies to which nodes the conversation goes from here 
    {
        node_2: goto node_2 on #messageHasData("name"); // when Dasha identifies that the user's phrase contains "name" data, as specified in the named entities section of data.json, a transfer to node node_2 happens 
    }
}

node node_2
{
    do
    {
        set $name =  #messageGetData("name")[0]?.value??""; //assign variable $name with the value extracted from the user's previous statement 
        #log($name);
        #say("pleased_meet", {name: $name} ); 
        wait*;
    }
}

digression policy_1
{
    conditions {on #messageHasIntent("policy_check");}
    do 
    {
        #say("what_policy"); 
        wait*;
    }
    transitions
    {
        policy_2: goto policy_2 on #messageHasData("policy");
    }
}

node policy_1_a
{
    do 
    {
        #say("what_policy_2"); 
        wait*;
    }
    transitions
    {
        policy_2: goto policy_2 on #messageHasData("policy");
    }
}

node policy_2
{
    do 
    {
        set $policy_number = #messageGetData("policy")[0]?.value??"";
        set $policy_read = external convert_policy($policy_number);
        #log($policy_read);
        #say("confirm_policy" , {policy_read: $policy_read} );
        wait*;
    }
    transitions
    {
        yes: goto policy_3 on #messageHasIntent("yes");
        no: goto policy_1_a on #messageHasIntent("no");
    }
}

node policy_3
{
    do
    {
        set $policy_status = external check_policy($policy_number);
        #say("verification_result", {policy_status: $policy_status} );
        wait*;
    }
    transitions
    {
        yes: goto can_help on #messageHasIntent("yes");
        no: goto bye_rate on #messageHasIntent("no");
    }
}

node can_help 
{
    do 
    {
        #say("can_help");
        wait*;
    }
}

node bye_rate
{
    do
    {
        #say("bye_rate");
        wait*;
    }
    transitions
    {
        rating_evaluation: goto rating_evaluation on #messageHasData("rating"); 
    }
}

node rating_evaluation 
{
    do 
    {
        set $rating =  #messageGetData("rating")[0]?.value??""; //assign variable $rating with the value extracted from the user's previous statement 
        #log($rating);
        var rating_num = #parseInt($rating); // #messageGetData collects data as an array of strings; we convert the string to an integer in order to evaluate whether the rating is positive or negative
        if ( rating_num >=7 ) 
        {
            goto rate_positive; // note that this function refers to the transition's name, not the node name 
        }
        else
        {
            goto rate_negative;
        }
    }
    transitions
    {
        rate_positive: goto rate_positive; // you need to declare transition name and the node it refers to here
        rate_negative: goto rate_negative;
    }
}

node rate_positive
{
    do 
    {
        #sayText("Thank you for such a high rating and thank you for your time. Please call back if you have any more questions. Bye!");
        exit;
    }
}

node rate_negative
{
    do 
    {
        #say("rate_negative");
        wait*;
    }
    transitions
    {
        neg_bye: goto neg_bye on true;  // "on true" is a condition which lets Dasha know to take the action if the user utters any phrase 
    }
    onexit // specifies an action that Dasha AI should take, as it exits the node. The action must be mapped to a transition
    {
        neg_bye: do
        {
            set $feedback = #getMessageText();
            #log($feedback);
        }
    }
}

node neg_bye
{
    do
    {
        #sayText("Thank you for sahring and thank you for your time. Please call back if you have any more questions. Bye!");
        exit;
    }
}

// digressions 

digression how_are_you
{
    conditions {on #messageHasIntent("how_are_you");}
    do 
    {
        #sayText("I'm well, thank you!", repeatMode: "ignore"); 
        #repeat(); // let the app know to repeat the phrase in the node from which the digression was called, when go back to the node 
        return; // go back to the node from which we got distracted into the digression 
    }
}

digression accident_coverage
{
    conditions {on #messageHasIntent("accident_coverage");}
    do 
    {
        #sayText("This policy does have full accident coverage enabled. Anything else I can help you with today?", repeatMode: "ignore"); 
        wait*;
    }
    transitions
    {
        yes: goto can_help on #messageHasIntent("yes");
        no: goto bye_rate on #messageHasIntent("no");
    }
}

digression claim_status
{
    conditions {on #messageHasIntent("claim_status");}
    do 
    {
        // Here I'm purposefully not calling an external function but am doing the random and calculations within the body of DSL to show you how you can too. Obviously for a use case such as this you would want to call up an external function and get the data from an external service 
        var foo = #random(); 
        if (foo >= .45)
        {
            set $claim = " the claim is due to be resolved on August 31st.";
        }
        else 
        {
            set $claim = " the claim has been approved.";
        }
        #say("claim_status", {claim: $claim} ); 
        wait*;
    }
    transitions
    {
        yes: goto can_help on #messageHasIntent("yes");
        no: goto bye_rate on #messageHasIntent("no");
    }
}

digression redeem_claim
{
    conditions {on #messageHasIntent("redeem_claim");}
    do 
    {
        #say("redeem_claim"); 
        wait*;
    }
    transitions
    {
        yes: goto refund on #messageHasIntent("yes");
        no: goto can_help on #messageHasIntent("no");
    }
}

node refund
{
    do
    {
        #sayText("Great. Refund process initiated. You should receive your money in three to five days. Anything else I can help you with?");
    }
    transitions
    {
        yes: goto can_help on #messageHasIntent("yes");
        no: goto bye_rate on #messageHasIntent("no");
    }
}

digression bye
{
    conditions {on #messageHasIntent("bye");}
    do
    {
        #sayText("Thanks for your time! Bye!");
        exit;
    }
}
