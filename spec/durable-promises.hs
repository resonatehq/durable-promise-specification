data IdVal a = IdVal
  { value :: Maybe a,
    idkey :: Maybe String
  }
  deriving (Show, Eq)

equals :: IdVal a -> IdVal b -> Bool
equals idVal1 idVal2 =
  case (idkey idVal1, idkey idVal2) of
    (Just key1, Just key2) ->
      key1 == key2
    _ ->
      False

data Promise p v e
  = Init
  | Pending {promiseParam :: IdVal p}
  | Resolved {promiseParam :: IdVal p, promiseValue :: IdVal v}
  | Rejected {promiseParam :: IdVal p, promiseError :: IdVal e}
  deriving (Show, Eq)

data Action p v e
  = Create (IdVal p)
  | Resolve (IdVal v)
  | Reject (IdVal e)
  | Cancel (IdVal e)
  | Timeout

data Result a
  = Success (Change a)
  | Failure Reason
  deriving (Show, Eq)

data Change a
  = Changed a
  | Unchanged a
  deriving (Show, Eq)

data Reason
  = AlreadyPending
  | AlreadyResolved
  | AlreadyRejected
  deriving (Show, Eq)

updatePromise :: Promise p a e -> Action p a e -> Result (Promise p a e)

-- Current State: Init
updatePromise Init (Create param) =
  Success (Changed (Pending param))
updatePromise Init (Resolve value) =
  Success (Changed (Resolved IdVal {value = Nothing, idkey = Nothing} value))
updatePromise Init (Reject error) =
  Success (Changed (Rejected IdVal {value = Nothing, idkey = Nothing} error))
updatePromise Init (Cancel error) =
  Success (Changed (Rejected IdVal {value = Nothing, idkey = Nothing} error))
updatePromise Init (Timeout) =
  Success (Changed (Rejected IdVal {value = Nothing, idkey = Nothing} IdVal {value = Nothing, idkey = Nothing}))

-- Current State: Pending
updatePromise (Pending param) (Resolve value) =
  Success (Changed (Resolved param value))
updatePromise (Pending param) (Reject error) =
  Success (Changed (Rejected param error))
updatePromise (Pending param) (Cancel error) =
  Success (Changed (Rejected param error))
updatePromise (Pending param) (Timeout) =
  Success (Changed (Rejected param IdVal {value = Nothing, idkey = Nothing}))
updatePromise p@(Pending oldParam) (Create newParam) =
  if equals oldParam newParam
    then Success (Unchanged p)
    else Failure AlreadyPending

-- Current State: Resolved
updatePromise p@(Resolved oldParam oldValue) (Create newParam) =
  if equals oldParam newParam
    then Success (Unchanged p)
    else Failure AlreadyResolved
updatePromise p@(Resolved oldParam oldValue) (Resolve newValue) =
  if equals oldValue newValue
    then Success (Unchanged p)
    else Failure AlreadyResolved
updatePromise (Resolved _ _) (Reject _) =
  Failure AlreadyResolved
updatePromise (Resolved _ _) (Cancel _) =
  Failure AlreadyResolved
updatePromise (Resolved _ _) (Timeout) =
  Failure AlreadyResolved

-- Current State: Rejected
updatePromise p@(Rejected oldParam oldError) (Create newParam) =
  if equals oldParam newParam
    then Success (Unchanged p)
    else Failure AlreadyRejected
updatePromise p@(Rejected oldParam oldError) (Reject newError) =
  if equals oldError newError
    then Success (Unchanged p)
    else Failure AlreadyRejected
updatePromise (Rejected _ _) (Resolve _) =
  Failure AlreadyRejected
updatePromise (Rejected oldParam oldError) (Cancel newError) =
  if equals oldError newError
    then Success (Unchanged (Rejected oldParam oldError))
    else Failure AlreadyRejected
updatePromise (Rejected oldParam oldError) (Timeout) =
  Success (Unchanged (Rejected oldParam oldError))