import { CachedPost } from "@/models/PostCache";
import SVGIcon from "@/utility/SVGIcon";

export default class ThumbnailEngine {

  /**
   * Renders a thumbnail element for a given post. If the post is null or missing a preview URL, returns null.
   * @param {CachedPost} post Post data to render
   * @returns {JQuery<HTMLElement> | null} Rendered thumbnail element or null if the post cannot be rendered
   */
  public static render (post: CachedPost): JQuery<HTMLElement> | null {
    // TODO: Login-blocked, Safe-blocked, or just missing preview = render placeholder thumbnail
    if (!post || !post.preview_url) return null;

    const article = $("<article>")
      .addClass("thumbnail")
      .attr(post.toAttributes());

    // Core
    const link = $("<a>")
      .addClass("thm-link")
      .attr({
        "href": `/posts/${post.id}`,
        "data-target": post.id,
      })
      .appendTo(article);

    $("<img>")
      .attr({
        "src": post.preview_url,
        "alt": "post #" + post.id,
      })
      .appendTo(link);

    // Footer
    const footer = $("<div>")
      .addClass(`thm-desc thm-rating-${post.rating}`)
      .appendTo(article);

    $("<span class='thm-desc-a'>")
      .appendTo(footer)
      .append(this.renderScore(post.score))
      .append(this.renderFavorites(post.fav_count))
      .append(this.renderComments(post.comment_count));

    this.renderRating(post.rating)
      .appendTo(footer);

    return article;
  }

  /**
   * Renders a placeholder thumbnail element
   * @returns {JQuery<HTMLElement>} Rendered placeholder thumbnail element
   */
  public static renderPlaceholder (): JQuery<HTMLElement> {
    return $("<article>")
      .addClass("thumbnail placeholder");
  }

  /* ===== Render Thumbnail Parts ===== */

  private static renderScore (score: number) {
    const scoreIcon = score > 0 ? "arrow_up_dash" : (score < 0 ? "arrow_down_dash" : "score");

    return $("<span>")
      .addClass("thm-desc-m thm-score")
      .addClass(score > 0 ? "thm-score-positive" : score < 0 ? "thm-score-negative" : "thm-score-neutral")
      .append(SVGIcon.render(scoreIcon))
      .append(Math.abs(score) + "");
  }

  private static renderFavorites (favCount: number) {
    return $("<span>")
      .addClass("thm-desc-m thm-favorites")
      .append(SVGIcon.render("favorites"))
      .append(favCount + "");
  }

  private static renderComments (commentCount: number) {
    return $("<span>")
      .addClass("thm-desc-m thm-comments")
      .append(SVGIcon.render("comments"))
      .append(commentCount + "");
  }

  private static renderRating (rating: string) {
    return $("<span>")
      .addClass("thm-desc-b thm-rating")
      .text(rating.toUpperCase());
  }
}
