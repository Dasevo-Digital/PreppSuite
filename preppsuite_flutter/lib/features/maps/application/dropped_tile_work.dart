import 'package:executor_lib/executor_lib.dart' show CancellationException;

/// Whether [error] is the map renderer dropping work for tiles nobody is
/// looking at any more (#207).
///
/// `vector_map_tiles` hands every tile to an executor with a callback that
/// says whether the tile is still wanted. Close the map, pan, or zoom, and
/// the tiles in flight are no longer wanted; the executor ends their jobs
/// with a [CancellationException]. That is the library working as meant.
///
/// The trouble is how one of those ends reaches nobody. Assembling a tile,
/// the library starts a job, then checks whether the tile is still wanted
/// and gives up *before* it waits for the job. The job's future is left
/// without a listener, and when the executor cancels it, Dart reports it
/// as an uncaught error -- one per tile, so a closed map left a dozen
/// "CancellationException: Cancelled" in the error log within a fifth of
/// a second, with no stack, because the executor completes them without
/// one. Nothing failed and nothing is missing: the tile was not going to
/// be drawn.
///
/// Only the executor's own exception is meant. Drift has a class of the
/// same name for a cancelled query; that one is not the map's, and if it
/// ever reaches the top it stays in the log.
bool isDroppedTileWork(Object error) => error is CancellationException;
