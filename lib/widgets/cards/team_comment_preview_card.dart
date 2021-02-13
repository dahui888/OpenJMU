///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2019-11-19 15:56
///
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:extended_text/extended_text.dart';

import 'package:openjmu/constants/constants.dart';
import 'package:openjmu/pages/post/team_post_detail_page.dart';

class TeamCommentPreviewCard extends StatelessWidget {
  const TeamCommentPreviewCard({
    Key key,
    @required this.topPost,
    @required this.detailPageState,
  }) : super(key: key);

  final TeamPost topPost;
  final TeamPostDetailPageState detailPageState;

  Future<void> confirmDelete(BuildContext context) async {
    final bool confirm = await ConfirmationDialog.show(
      context,
      title: '删除此楼',
      content: '是否删除该楼内容',
      showConfirm: true,
    );
    if (confirm) {
      delete(context);
    }
  }

  void delete(BuildContext context) {
    final TeamPostProvider p = context.read<TeamPostProvider>();
    final TeamPost post = context.read<TeamPostProvider>().post;
    TeamPostAPI.deletePost(postId: post.tid, postType: 7).then(
      (dynamic _) {
        showToast('删除成功');
        p.commentDeleted();
        Instances.eventBus.fire(TeamCommentDeletedEvent(
          postId: post.tid,
          topPostId: topPost.tid,
        ));
      },
    );
  }

  Widget _header(BuildContext context, TeamPost post) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Text(
                post.nickname ?? post.uid.toString(),
                style: TextStyle(
                  height: 1.2,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gap(6.w),
              _postTime(context, post),
              if (post.uid == topPost.uid)
                Text(
                  ' (楼主)',
                  style: context.textTheme.caption.copyWith(
                    height: 1.2,
                    fontSize: 17.sp,
                  ),
                ),
              if (Constants.developerList.contains(post.uid))
                Padding(
                  padding: EdgeInsets.only(left: 6.w),
                  child: const DeveloperTag(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _postTime(BuildContext context, TeamPost post) {
    return Text(
      '${post.floor}L · ${TeamPostAPI.timeConverter(post)}',
      style: context.textTheme.caption.copyWith(
        height: 1.2,
        fontSize: 16.sp,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  Widget _content(TeamPost post) {
    return Tapper(
      child: ExtendedText(
        post.content ?? '',
        style: TextStyle(height: 1.2, fontSize: 17.sp),
        onSpecialTextTap: specialTextTapRecognizer,
        maxLines: 8,
        overflowWidget: contentOverflowWidget,
        specialTextSpanBuilder: StackSpecialTextSpanBuilder(),
      ),
    );
  }

  Widget _replyInfo(BuildContext context, TeamPost post) {
    return Tapper(
      onTap: () {
        if (post.replyInfo != null && post.replyInfo.isNotEmpty) {
          final TeamPostProvider provider = TeamPostProvider(post);
          navigatorState.pushNamed(
            Routes.openjmuTeamPostDetail.name,
            arguments: Routes.openjmuTeamPostDetail.d(
              provider: provider,
              type: TeamPostType.comment,
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(top: 12.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.w),
          color: Theme.of(context).canvasColor.withOpacity(0.5),
        ),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: post.replyInfo.length +
              (post.replyInfo.length != post.repliesCount ? 1 : 0),
          itemBuilder: (_, int index) {
            if (index == post.replyInfo.length) {
              return Padding(
                padding: EdgeInsets.only(top: 14.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.expand_more,
                      size: 20.w,
                      color: context.textTheme.caption.color,
                    ),
                    Text(
                      '查看更多回复',
                      style: context.textTheme.caption.copyWith(
                        fontSize: 15.sp,
                      ),
                    ),
                    Icon(
                      Icons.expand_more,
                      size: 20.w,
                      color: context.textTheme.caption.color,
                    ),
                  ],
                ),
              );
            }
            final Map<String, dynamic> _post =
                post.replyInfo[index].cast<String, dynamic>();
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ExtendedText(
                      _post['content'] as String,
                      specialTextSpanBuilder: StackSpecialTextSpanBuilder(
                        prefixSpans: <InlineSpan>[
                          TextSpan(
                            text: '@${_post['user']['nickname']}',
                            style: const TextStyle(color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                navigatorState.pushNamed(
                                  Routes.openjmuUserPage.name,
                                  arguments: Routes.openjmuUserPage.d(
                                    uid: _post['user']['uid'].toString(),
                                  ),
                                );
                              },
                          ),
                          if (_post['user']['uid'].toString() == topPost.uid)
                            const TextSpan(text: '(楼主)'),
                          const TextSpan(
                            text: ': ',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                      style: context.textTheme.bodyText2.copyWith(
                        height: 1.2,
                        fontSize: 17.sp,
                      ),
                      onSpecialTextTap: specialTextTapRecognizer,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _images(BuildContext context, TeamPost post) {
    final List<Widget> imagesWidget = <Widget>[];
    for (int index = 0; index < post.pics.length; index++) {
      final int imageId = post.pics[index]['fid'].toString().toInt();
      final String imageUrl = API.teamFile(fid: imageId);
      Widget _exImage = ExtendedImage.network(
        imageUrl,
        fit: BoxFit.cover,
        cache: true,
        color: currentIsDark ? Colors.black.withAlpha(50) : null,
        colorBlendMode: currentIsDark ? BlendMode.darken : BlendMode.srcIn,
        loadStateChanged: (ExtendedImageState state) {
          Widget loader;
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              loader = DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.w),
                  color: context.theme.dividerColor,
                ),
              );
              break;
            case LoadState.completed:
              final ImageInfo info = state.extendedImageInfo;
              if (info != null) {
                loader = ScaledImage(
                  image: info.image,
                  length: post.pics.length,
                  num200: 200.sp,
                  num400: 400.sp,
                );
              }
              break;
            case LoadState.failed:
              break;
          }
          return loader;
        },
      );
      _exImage = Tapper(
        onTap: () {
          navigatorState.pushNamed(
            Routes.openjmuImageViewer.name,
            arguments: Routes.openjmuImageViewer.d(
              index: index,
              pics: post.pics.map<ImageBean>((dynamic _) {
                return ImageBean(
                  id: imageId,
                  imageUrl: imageUrl,
                  imageThumbUrl: imageUrl,
                  postId: post.tid,
                );
              }).toList(),
            ),
          );
        },
        child: _exImage,
      );
      _exImage = Hero(
        tag: 'team-comment-preview-image-${post.tid}-$imageId',
        child: _exImage,
        placeholderBuilder: (_, __, Widget child) => child,
      );
      imagesWidget.add(_exImage);
    }
    Widget _image;
    if (post.pics.length == 1) {
      _image = Align(
        alignment: Alignment.topLeft,
        child: imagesWidget[0],
      );
    } else if (post.pics.length > 1) {
      _image = GridView.count(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        primary: false,
        mainAxisSpacing: 10.sp,
        crossAxisCount: 3,
        crossAxisSpacing: 10.sp,
        children: imagesWidget,
      );
    }
    _image = Padding(
      padding: EdgeInsets.only(
        top: 6.h,
      ),
      child: _image,
    );
    return _image;
  }

  @override
  Widget build(BuildContext context) {
    return Selector<TeamPostProvider, TeamPost>(
      selector: (_, TeamPostProvider p) => p.post,
      builder: (_, TeamPost post, __) => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(width: 1.w, color: context.theme.dividerColor),
          ),
          color: context.theme.cardColor,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            UserAPI.getAvatar(uid: post.uid),
            Gap(16.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _header(context, post),
                  VGap(12.w),
                  _content(post),
                  if (post.pics != null && post.pics.isNotEmpty)
                    _images(context, post),
                  if (post.replyInfo != null && post.replyInfo.isNotEmpty)
                    _replyInfo(context, post),
                ],
              ),
            ),
            Tapper(
              child: Container(
                width: 48.w,
                height: 48.w,
                alignment: AlignmentDirectional.topEnd,
                child: Icon(
                  Icons.reply,
                  size: 30.w,
                  color: Theme.of(context).dividerColor,
                ),
              ),
              onTap: () {
                detailPageState.setReplyToPost(post);
              },
            ),
            if (topPost.uid == currentUser.uid || post.uid == currentUser.uid)
              SizedBox.fromSize(
                size: Size.square(50.w),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).dividerColor,
                  ),
                  iconSize: 40.w,
                  onPressed: () => confirmDelete(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
