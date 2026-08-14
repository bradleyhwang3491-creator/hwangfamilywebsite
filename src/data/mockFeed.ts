import type { ActivityCategory, CategoryMeta, FamilyMember, FeedItem } from '../types';

export const CATEGORY_META: Record<ActivityCategory, CategoryMeta> = {
  travel: { label: '여행', emoji: '✈️', color: '#111827', bg: '#F1F5F9' },
  running: { label: '러닝', emoji: '🏃', color: '#111827', bg: '#F1F5F9' },
  golf: { label: '골프', emoji: '⛳', color: '#111827', bg: '#F1F5F9' },
  gym: { label: '헬스', emoji: '💪', color: '#111827', bg: '#F1F5F9' },
};

export const FAMILY: FamilyMember[] = [
  { id: 'dad', name: '아빠', avatarColor: '#111827', initial: '아' },
  { id: 'mom', name: '엄마', avatarColor: '#6B7280', initial: '엄' },
  { id: 'yiseo', name: '이서', avatarColor: '#9CA3AF', initial: '이' },
];

export const MOCK_FEED: FeedItem[] = [
  {
    id: 'f1',
    category: 'travel',
    title: '제주도 가족 여행, 협재 바다 앞에서',
    summary: '3박 4일 제주 일정 첫날, 협재 해수욕장에서 노을을 봤다. 이서가 처음으로 파도에 발을 담근 날.',
    thumbnail: 'https://images.unsplash.com/photo-1546874177-9e664107314e?w=800&q=80',
    createdAt: '3시간 전',
    location: '제주 협재',
    stats: [{ icon: '📍', label: '제주 4일차 중 1일' }, { icon: '📷', label: '사진 24장' }],
    members: [FAMILY[0], FAMILY[1], FAMILY[2]],
    likeCount: 12,
    imageCount: 24,
  },
  {
    id: 'f2',
    category: 'running',
    title: '한강 아침 러닝, 오늘도 완주',
    summary: '반포한강공원 5km 코스. 날씨가 선선해서 페이스가 잘 나왔다.',
    thumbnail: 'https://images.unsplash.com/photo-1571008887538-b36bb32f4571?w=800&q=80',
    createdAt: '어제',
    location: '반포한강공원',
    stats: [{ icon: '🏃', label: '5.2 km' }, { icon: '⏱', label: '28:14' }, { icon: '🔥', label: '312 kcal' }],
    members: [FAMILY[0]],
    likeCount: 6,
  },
  {
    id: 'f3',
    category: 'golf',
    title: '아빠와 첫 스크린 골프',
    summary: '이서와 처음으로 스크린 골프장에 갔다. 생각보다 잘 따라와서 놀랐다.',
    thumbnail: 'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?w=800&q=80',
    createdAt: '2일 전',
    location: '강남 스크린골프',
    stats: [{ icon: '⛳', label: '9홀 · 46타' }, { icon: '🏌️', label: '드라이버 평균 180m' }],
    members: [FAMILY[0], FAMILY[2]],
    likeCount: 9,
  },
  {
    id: 'f4',
    category: 'gym',
    title: '하체의 날, 스쿼트 개인 최고 기록',
    summary: '스쿼트 80kg 5x5 성공. 무릎 각도 신경 쓰며 진행.',
    thumbnail: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80',
    createdAt: '3일 전',
    stats: [{ icon: '💪', label: '스쿼트 80kg' }, { icon: '⏱', label: '52분' }, { icon: '🔁', label: '5세트' }],
    members: [FAMILY[1]],
    likeCount: 4,
  },
  {
    id: 'f5',
    category: 'travel',
    title: '경주 벚꽃 나들이',
    summary: '보문호수 벚꽃길을 따라 자전거를 탔다. 이서가 세발자전거 졸업.',
    thumbnail: 'https://images.unsplash.com/photo-1522383225653-ed111181a951?w=800&q=80',
    createdAt: '1주 전',
    location: '경주 보문호',
    stats: [{ icon: '📍', label: '당일치기' }, { icon: '📷', label: '사진 18장' }],
    members: [FAMILY[0], FAMILY[1], FAMILY[2]],
    likeCount: 15,
    imageCount: 18,
  },
];
