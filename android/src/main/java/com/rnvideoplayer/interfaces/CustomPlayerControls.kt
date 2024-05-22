import android.view.View

interface ICustomPlayerControls {
  fun setPlayPauseButtonClickListener(listener: View.OnClickListener)
  fun setFullScreenButtonClickListener(listener: View.OnClickListener)
  fun setSettingsButtonClickListener(listener: View.OnClickListener)
  fun morphPlayPause(isPlaying: Boolean)
  fun setVisibilityPlayPauseButton(isVisible: Boolean)
  fun morphFullScreen(isFullScreen: Boolean)
}
