import android.view.View
import android.view.View.OnClickListener

interface ICustomPlayerControls {
  fun setPlayPauseButtonClickListener(listener: View.OnClickListener)
  fun setFullScreenButtonClickListener(listener: View.OnClickListener)
  fun setSettingsButtonClickListener(listener: View.OnClickListener)
  fun setReplayButtonClickListener(listener: View.OnClickListener)
  fun setPlayerViewClickListener(listener: OnClickListener)
  fun morphPlayPause(isPlaying: Boolean)
  fun setVisibilityPlayPauseButton(isVisible: Boolean)
  fun setVisibilityReplayButton(isVisible: Boolean)
  fun setVisibilitySettingsButton(isVisible: Boolean)
  fun morphFullScreen(isFullScreen: Boolean)
  fun hideControls()
  fun showControls()
  fun timeoutControls()
}
