## ZonedDateTime-Period Arithmetic

`ZonedDateTime` uses calendrical arithmetic in a [similar manner to `DateTime`](http://julia.readthedocs.io/en/latest/manual/dates/#timetype-period-arithmetic) but with some key differences. Lets look at these differences by adding a day to March 30th 2014 in Europe/Warsaw.

```julia
julia> using Base.Dates

julia> warsaw = TimeZone("Europe/Warsaw")
Europe/Warsaw (UTC+1/UTC+2)

julia> spring = ZonedDateTime(2014, 3, 30, warsaw)
2014-03-30T00:00:00+01:00

julia> spring + Day(1)
2014-03-31T00:00:00+02:00
```

Adding a day to the `ZonedDateTime` changed the date from the 30th to the 31st as expected. Looking closely however you'll notice that the time zone offset changed from +01:00 to +02:00. The reason for this change is because the time zone "Europe/Warsaw" switched from standard time (+01:00) to daylight saving time (+02:00) on the 30th. The change in the offset caused the local DateTime 2014-03-31T02:00:00 to be skipped effectively making the 30th a day which only contained 23 hours. Alternatively if we added hours we can see the difference:

```julia
julia> spring + Hour(24)
2014-03-31T01:00:00+02:00

julia> spring + Hour(23)
2014-03-31T00:00:00+02:00
```

A potential cause of confusion regarding this behaviour is the loss in associativity when ordering is forced. For example:

```julia
julia> (spring + Day(1)) + Hour(24)
2014-04-01T00:00:00+02:00

julia> (spring + Hour(24)) + Day(1)
2014-04-01T01:00:00+02:00
```

The first example adds 1 day to 2014-03-30T00:00:00+01:00, which results in 2014-03-31T00:00:00+02:00; then we add 24 hours to get 2014-04-01T00:00:00+02:00. The second example add 24 hours *first* to get 2014-03-31T01:00:00+02:00, and *then* add 1 day which results in 2014-04-01T01:00:00+02:00. When working with operations using multiple periods the operations will be ordered by the Period's *types* and not their positional order; this means `Day` will be added before `Hour`. Hence the following *does* result in associativity:

```julia
julia> spring + Hour(24) + Day(1)
2014-04-01T00:00:00+02:00

julia> spring + Day(1) + Hour(24)
2014-04-01T00:00:00+02:00
```

If using a version of Julia 0.5 or below you may want to force precedence when mixing `DatePeriod`s and `TimePeriod`s since the expression `Day(1) + Hour(24)` would be automatically canonicalized to `Day(2)`:

```julia
julia> ZonedDateTime(2014, 10, 25, warsaw) + Day(1) + Hour(24)  # On Julia 0.5 or below
2014-10-27T00:00:00+01:00

julia> ZonedDateTime(2014, 10, 25, warsaw) + Day(2)
2014-10-27T00:00:00+01:00
```

In Julia 0.6 period canonicalization no longer happens automatically:

```
julia> ZonedDateTime(2014, 10, 25, warsaw) + Day(1) + Hour(24)  # Julia 0.6 and above
2014-10-26T23:00:00+01:00
```

## Ranges

Julia allows for the use of powerful [adjuster functions](http://julia.readthedocs.io/en/latest/manual/dates/#adjuster-functions) to perform certain cendrical and temporal calculations. The `recur()` function, for example, can take a `StepRange` of `TimeType`s and apply a function to produce a vector of dates that fit certain inclusion criteria (for example, "every fifth Wednesday of the month in 2014 at 09:00"):

```julia
julia> warsaw = TimeZone("Europe/Warsaw")
Europe/Warsaw (UTC+1/UTC+2)

julia> start = ZonedDateTime(2014, warsaw)
2014-01-01T00:00:00+01:00

julia> stop = ZonedDateTime(2015, warsaw)
2015-01-01T00:00:00+01:00

julia> Dates.recur(start:Dates.Hour(1):stop) do d
           Dates.dayofweek(d) == Dates.Wednesday &&
           Dates.hour(d) == 9 &&
           Dates.dayofweekofmonth(d) == 5
       end
5-element Array{TimeZones.ZonedDateTime,1}:
 2014-01-29T09:00:00+01:00
 2014-04-30T09:00:00+02:00
 2014-07-30T09:00:00+02:00
 2014-10-29T09:00:00+01:00
 2014-12-31T09:00:00+01:00
```

Note the transition from standard time to daylight saving time (and back again).

It is possible to define a range `start:step:stop` such that `start` and `stop` have different time zones. In this case the resulting `ZonedDateTime`s will all share a time zone with `start` but the range will stop at the instant that corresponds to `stop` in `start`'s time zone. For example:

```julia
julia> start = ZonedDateTime(2016, 1, 1, 12, TimeZone("UTC"))
2016-01-01T12:00:00+00:00

julia> stop = ZonedDateTime(2016, 1, 1, 18, TimeZone("Europe/Warsaw"))
2016-01-01T18:00:00+01:00

julia> collect(start:Dates.Hour(1):stop)
6-element Array{TimeZones.ZonedDateTime,1}:
 2016-01-01T12:00:00+00:00
 2016-01-01T13:00:00+00:00
 2016-01-01T14:00:00+00:00
 2016-01-01T15:00:00+00:00
 2016-01-01T16:00:00+00:00
 2016-01-01T17:00:00+00:00
```

Note that 2016-01-01T17:00:00 in UTC corresponds to 2016-01-01T18:00:00 in "Europe/Warsaw", which is the requested endpoint of the range.
