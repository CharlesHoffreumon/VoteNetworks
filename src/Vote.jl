module Vote
using VoteNetworks.World
using MetaGraphs
using LightGraphs

export call_to_election, plurality_voting

struct fullVote
    ballots::Array
    winner::Symbol
end

function cast_ballot(voter, function_of_choice, preferences, beliefs, attributes, candidates)
    return function_of_choice(preference,beliefs, attributes, candidates)
end

function call_to_election(world, function_of_choice, censorship_criterion = :universal, candidates = :all)
    if candidates == :all
        candidates = world.parties
    end
    voters = censorship(world, censorship_criterion)
    ballots = [cast_ballot(voter, function_of_choice, MetaGraphs.get_prop(world.network, voter, :preferences), MetaGraphs.get_prop(world.network, voter, :beliefs), MetaGraphs.get_prop(world.network, voter, :attributes), candidates) for voter in voters]
    return ballots
end

function plurality_voting(ballots)
    results = Dict()
    for ballot in ballots
        for (key, value) in ballot
            if value == max(values(ballot))
                results[key] = get(results, key, 0) + 1
            end
        end
    end
    winner = :nothing
    for (key, value) in results
        if value == max(values(results))
            winner = key
        end
    end
    return fullVote(ballots, winner)
end

end
