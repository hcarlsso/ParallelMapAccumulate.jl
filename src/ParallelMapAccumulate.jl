module ParallelMapAccumulate

using Distributed

export pmapaccumulate

using Base: AsyncGenerator
using Distributed: wrap_on_error, wrap_retry

pmapaccumulate(f, op, p::AbstractWorkerPool, c1, c...; kwargs...) = pmapaccumulate(
    a->f(a...), op, p, zip(c1, c...); kwargs...
)
pmapaccumulate(f, op, c; kwargs...) = pmapaccumulate(
    f, op, default_worker_pool(), c; kwargs...
)
pmapaccumulate(f, op, c1, c...; kwargs...) = pmapaccumulate(
    a->f(a...), op, zip(c1, c...); kwargs...
)

function pmapaccumulate(f, op, p::AbstractWorkerPool, c;
                        distributed=true, on_error=nothing,
                        retry_delays=[], retry_check=nothing)

    # Don't do remote calls if there are no workers.
    if (length(p) == 0) || (length(p) == 1 && fetch(p.channel) == myid())
        distributed = false
    end

    if on_error !== nothing
        f = wrap_on_error(f, on_error)
    end

    if distributed
        f = remote(p, f)
    end

    if length(retry_delays) > 0
        f = wrap_retry(f, retry_delays, retry_check)
    end

    iter = AsyncGenerator(f, c; ntasks = ()->nworkers(p))

    return Iterators.accumulate(op, iter)
end

end # module
