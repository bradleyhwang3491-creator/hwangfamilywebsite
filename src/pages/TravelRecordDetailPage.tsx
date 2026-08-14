import { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import BottomNav from '../components/BottomNav';
import { supabase } from '../lib/supabaseClient';
import { geocodeAddress, type GeocodeResult } from '../lib/geocode';
import { resizeImageToLimit } from '../lib/imageResize';

const MAX_PHOTOS = 10;

interface TravelRecord {
  id: string;
  title: string;
  region: string;
  address: string;
  country: string | null;
  lat: number | null;
  lng: number | null;
  is_domestic: boolean | null;
  start_date: string;
  end_date: string;
  content: string;
}

interface ExistingPhoto {
  id: string;
  storage_path: string;
  url: string;
}

interface NewPhotoDraft {
  file: File;
  previewUrl: string;
}

function daysBetween(start: string, end: string) {
  const ms = new Date(end).getTime() - new Date(start).getTime();
  return Math.round(ms / 86_400_000) + 1;
}

export default function TravelRecordDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [record, setRecord] = useState<TravelRecord | null>(null);
  const [photos, setPhotos] = useState<ExistingPhoto[]>([]);
  const [loading, setLoading] = useState(true);
  const [notFound, setNotFound] = useState(false);
  const [mode, setMode] = useState<'view' | 'edit'>('view');
  const [confirmingDelete, setConfirmingDelete] = useState(false);
  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  // Edit form state
  const [title, setTitle] = useState('');
  const [region, setRegion] = useState('');
  const [address, setAddress] = useState('');
  const [geo, setGeo] = useState<GeocodeResult | null>(null);
  const [geocoding, setGeocoding] = useState(false);
  const [geoError, setGeoError] = useState<string | null>(null);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [content, setContent] = useState('');
  const [removedPhotoIds, setRemovedPhotoIds] = useState<string[]>([]);
  const [newPhotos, setNewPhotos] = useState<NewPhotoDraft[]>([]);

  useEffect(() => {
    if (!id) return;
    loadRecord(id);
  }, [id]);

  async function loadRecord(recordId: string) {
    setLoading(true);
    const { data: rec } = await supabase
      .from('travel_records')
      .select('id, title, region, address, country, lat, lng, is_domestic, start_date, end_date, content')
      .eq('id', recordId)
      .maybeSingle();

    if (!rec) {
      setNotFound(true);
      setLoading(false);
      return;
    }

    const { data: photoRows } = await supabase
      .from('travel_record_photos')
      .select('id, storage_path')
      .eq('travel_record_id', recordId)
      .order('sort_order');

    const loadedPhotos: ExistingPhoto[] = (photoRows ?? []).map((p) => ({
      id: p.id,
      storage_path: p.storage_path,
      url: supabase.storage.from('travel-photos').getPublicUrl(p.storage_path).data.publicUrl,
    }));

    setRecord(rec);
    setPhotos(loadedPhotos);
    setLoading(false);
  }

  function enterEditMode() {
    if (!record) return;
    setTitle(record.title);
    setRegion(record.region);
    setAddress(record.address);
    setGeo(
      record.lat != null && record.lng != null
        ? { lat: record.lat, lng: record.lng, country: record.country, isDomestic: !!record.is_domestic }
        : null,
    );
    setStartDate(record.start_date);
    setEndDate(record.end_date);
    setContent(record.content);
    setRemovedPhotoIds([]);
    setNewPhotos([]);
    setError(null);
    setMode('edit');
  }

  function cancelEdit() {
    newPhotos.forEach((p) => URL.revokeObjectURL(p.previewUrl));
    setNewPhotos([]);
    setRemovedPhotoIds([]);
    setMode('view');
  }

  async function handleCheckAddress() {
    if (!address.trim()) return;
    setGeocoding(true);
    setGeoError(null);
    setGeo(null);
    const result = await geocodeAddress(address.trim());
    setGeocoding(false);
    if (!result) {
      setGeoError('주소를 찾지 못했습니다. 다르게 입력해보세요.');
      return;
    }
    setGeo(result);
  }

  const remainingExistingCount = photos.filter((p) => !removedPhotoIds.includes(p.id)).length;

  async function handlePhotoSelect(files: FileList | null) {
    if (!files) return;
    const remaining = MAX_PHOTOS - remainingExistingCount - newPhotos.length;
    const selected = Array.from(files).slice(0, remaining);
    const resized = await Promise.all(selected.map((f) => resizeImageToLimit(f)));
    const next = resized.map((file) => ({ file, previewUrl: URL.createObjectURL(file) }));
    setNewPhotos((prev) => [...prev, ...next]);
  }

  function removeNewPhoto(index: number) {
    setNewPhotos((prev) => {
      URL.revokeObjectURL(prev[index].previewUrl);
      return prev.filter((_, i) => i !== index);
    });
  }

  const formValid =
    title.trim().length > 0 &&
    region.trim().length > 0 &&
    geo !== null &&
    startDate.length > 0 &&
    endDate.length > 0 &&
    endDate >= startDate &&
    content.trim().length > 0;

  async function handleSave() {
    if (!record || !formValid || !geo) return;
    setSaving(true);
    setError(null);

    const { error: updateError } = await supabase
      .from('travel_records')
      .update({
        title: title.trim(),
        region: region.trim(),
        address: address.trim(),
        country: geo.country,
        lat: geo.lat,
        lng: geo.lng,
        is_domestic: geo.isDomestic,
        start_date: startDate,
        end_date: endDate,
        content: content.trim(),
        updated_at: new Date().toISOString(),
      })
      .eq('id', record.id);

    if (updateError) {
      setSaving(false);
      setError('저장 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      return;
    }

    if (removedPhotoIds.length > 0) {
      const removed = photos.filter((p) => removedPhotoIds.includes(p.id));
      await supabase.storage.from('travel-photos').remove(removed.map((p) => p.storage_path));
      await supabase.from('travel_record_photos').delete().in('id', removedPhotoIds);
    }

    let sortOrder = remainingExistingCount;
    for (const draft of newPhotos) {
      const ext = draft.file.name.split('.').pop();
      const path = `${record.id}/${sortOrder}-${Date.now()}.${ext}`;
      const { error: uploadError } = await supabase.storage.from('travel-photos').upload(path, draft.file);
      if (!uploadError) {
        await supabase.from('travel_record_photos').insert({
          travel_record_id: record.id,
          storage_path: path,
          sort_order: sortOrder,
        });
      }
      sortOrder++;
    }

    newPhotos.forEach((p) => URL.revokeObjectURL(p.previewUrl));
    setNewPhotos([]);
    setMode('view');
    setSaving(false);
    await loadRecord(record.id);
  }

  async function handleDelete() {
    if (!record) return;
    setSaving(true);
    if (photos.length > 0) {
      await supabase.storage.from('travel-photos').remove(photos.map((p) => p.storage_path));
    }
    await supabase.from('travel_records').delete().eq('id', record.id);
    navigate('/travel');
  }

  if (loading) {
    return (
      <div className="app-frame">
        <DetailHeader onBack={() => navigate('/travel')} title="기록 상세" />
        <BottomNav />
      </div>
    );
  }

  if (notFound || !record) {
    return (
      <div className="app-frame">
        <DetailHeader onBack={() => navigate('/travel')} title="기록 상세" />
        <main className="flex-1 flex items-center justify-center px-5 pb-28">
          <p className="text-[14px] text-text-400">기록을 찾을 수 없습니다.</p>
        </main>
        <BottomNav />
      </div>
    );
  }

  return (
    <div className="app-frame">
      <DetailHeader onBack={() => navigate('/travel')} title={mode === 'edit' ? '기록 수정' : '기록 상세'} />

      <main className="flex-1 overflow-y-auto px-5 pt-4 pb-28">
        {mode === 'view' ? (
          <div className="flex flex-col gap-4">
            <div>
              <h2 className="text-[19px] font-bold text-text-900 mb-1">{record.title}</h2>
              <p className="text-[13px] text-text-600">
                {record.country ?? ''} {record.country ? '·' : ''} {record.region}
              </p>
              <p className="text-[12px] text-text-400 mt-0.5">
                {record.start_date} ~ {record.end_date} · {daysBetween(record.start_date, record.end_date)}일
              </p>
            </div>

            {photos.length > 0 && (
              <div className="grid grid-cols-3 gap-2">
                {photos.map((p, i) => (
                  <button
                    key={p.id}
                    type="button"
                    onClick={() => setLightboxIndex(i)}
                    className="aspect-square rounded-lg overflow-hidden border border-gray-border"
                  >
                    <img src={p.url} alt="" className="w-full h-full object-cover" />
                  </button>
                ))}
              </div>
            )}

            <p className="text-[14px] text-text-900 leading-relaxed whitespace-pre-wrap">{record.content}</p>

            <div className="flex gap-2 pt-2">
              <button
                type="button"
                onClick={enterEditMode}
                className="flex-1 h-12 rounded-xl border text-[14px] font-semibold text-text-900"
                style={{ borderColor: '#E5E7EB' }}
              >
                수정
              </button>
              {!confirmingDelete ? (
                <button
                  type="button"
                  onClick={() => setConfirmingDelete(true)}
                  className="flex-1 h-12 rounded-xl border text-[14px] font-semibold"
                  style={{ borderColor: '#E5E7EB', color: '#111827' }}
                >
                  삭제
                </button>
              ) : (
                <div className="flex-1 flex gap-2">
                  <button
                    type="button"
                    onClick={handleDelete}
                    disabled={saving}
                    className="flex-1 h-12 rounded-xl text-white text-[14px] font-semibold disabled:opacity-50"
                    style={{ background: '#111827' }}
                  >
                    {saving ? '삭제 중...' : '정말 삭제'}
                  </button>
                  <button
                    type="button"
                    onClick={() => setConfirmingDelete(false)}
                    className="flex-1 h-12 rounded-xl border text-[14px] font-semibold text-text-600"
                    style={{ borderColor: '#E5E7EB' }}
                  >
                    취소
                  </button>
                </div>
              )}
            </div>
          </div>
        ) : (
          <div className="flex flex-col gap-5">
            <Field label="제목">
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full h-12 px-4 rounded-xl border text-[15px] text-text-900"
                style={{ borderColor: '#E5E7EB' }}
              />
            </Field>

            <Field label="지역">
              <input
                value={region}
                onChange={(e) => setRegion(e.target.value)}
                className="w-full h-12 px-4 rounded-xl border text-[15px] text-text-900"
                style={{ borderColor: '#E5E7EB' }}
              />
            </Field>

            <Field label="지역 주소">
              <div className="flex gap-2">
                <input
                  value={address}
                  onChange={(e) => {
                    setAddress(e.target.value);
                    setGeo(null);
                  }}
                  className="flex-1 h-12 px-4 rounded-xl border text-[15px] text-text-900"
                  style={{ borderColor: '#E5E7EB' }}
                />
                <button
                  type="button"
                  onClick={handleCheckAddress}
                  disabled={!address.trim() || geocoding}
                  className="shrink-0 h-12 px-4 rounded-xl text-[14px] font-semibold text-white disabled:opacity-40"
                  style={{ background: '#111827' }}
                >
                  {geocoding ? '확인 중' : '위치 확인'}
                </button>
              </div>
              {geoError && (
                <p className="text-[12px] mt-1.5 font-semibold" style={{ color: '#111827' }}>
                  {geoError}
                </p>
              )}
              {geo && (
                <p className="text-[12px] mt-1.5 text-text-600">
                  ✓ 위치 확인됨 — {geo.country ?? '알 수 없음'} ({geo.isDomestic ? '한국' : '해외'})
                </p>
              )}
            </Field>

            <Field label="여행 일자">
              <div className="flex items-center gap-2">
                <input
                  type="date"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  className="flex-1 h-12 px-3 rounded-xl border text-[14px] text-text-900"
                  style={{ borderColor: '#E5E7EB' }}
                />
                <span className="text-text-400">~</span>
                <input
                  type="date"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  min={startDate || undefined}
                  className="flex-1 h-12 px-3 rounded-xl border text-[14px] text-text-900"
                  style={{ borderColor: '#E5E7EB' }}
                />
              </div>
            </Field>

            <Field label="여행 기록">
              <textarea
                value={content}
                onChange={(e) => setContent(e.target.value)}
                rows={6}
                className="w-full px-4 py-3 rounded-xl border text-[15px] text-text-900 resize-none"
                style={{ borderColor: '#E5E7EB' }}
              />
            </Field>

            <Field label={`사진 첨부 (${remainingExistingCount + newPhotos.length}/${MAX_PHOTOS})`}>
              <div className="grid grid-cols-4 gap-2">
                {photos
                  .filter((p) => !removedPhotoIds.includes(p.id))
                  .map((p) => (
                    <div key={p.id} className="relative aspect-square rounded-lg overflow-hidden border border-gray-border">
                      <img src={p.url} alt="" className="w-full h-full object-cover" />
                      <button
                        type="button"
                        onClick={() => setRemovedPhotoIds((prev) => [...prev, p.id])}
                        aria-label="사진 삭제"
                        className="absolute top-1 right-1 w-5 h-5 rounded-full flex items-center justify-center text-white text-[12px]"
                        style={{ background: 'rgba(17,24,39,0.75)' }}
                      >
                        ×
                      </button>
                    </div>
                  ))}
                {newPhotos.map((p, i) => (
                  <div key={p.previewUrl} className="relative aspect-square rounded-lg overflow-hidden border border-gray-border">
                    <img src={p.previewUrl} alt="" className="w-full h-full object-cover" />
                    <button
                      type="button"
                      onClick={() => removeNewPhoto(i)}
                      aria-label="사진 삭제"
                      className="absolute top-1 right-1 w-5 h-5 rounded-full flex items-center justify-center text-white text-[12px]"
                      style={{ background: 'rgba(17,24,39,0.75)' }}
                    >
                      ×
                    </button>
                  </div>
                ))}
                {remainingExistingCount + newPhotos.length < MAX_PHOTOS && (
                  <label
                    className="aspect-square rounded-lg border border-dashed flex items-center justify-center text-text-400 text-[22px] cursor-pointer"
                    style={{ borderColor: '#E5E7EB' }}
                  >
                    +
                    <input
                      type="file"
                      accept="image/*"
                      multiple
                      className="hidden"
                      onChange={(e) => handlePhotoSelect(e.target.files)}
                    />
                  </label>
                )}
              </div>
            </Field>

            {error && (
              <p className="text-[13px] text-center font-semibold" style={{ color: '#111827' }}>
                {error}
              </p>
            )}

            <div className="flex gap-2">
              <button
                type="button"
                onClick={handleSave}
                disabled={!formValid || saving}
                className="flex-1 h-12 rounded-xl text-white text-[15px] font-medium disabled:opacity-40"
                style={{ background: '#111827' }}
              >
                {saving ? '저장 중...' : '저장'}
              </button>
              <button
                type="button"
                onClick={cancelEdit}
                disabled={saving}
                className="flex-1 h-12 rounded-xl border text-[15px] font-medium text-text-600"
                style={{ borderColor: '#E5E7EB' }}
              >
                취소
              </button>
            </div>
          </div>
        )}
      </main>

      {lightboxIndex !== null && photos[lightboxIndex] && (
        <PhotoLightbox
          photos={photos}
          index={lightboxIndex}
          onClose={() => setLightboxIndex(null)}
          onChangeIndex={setLightboxIndex}
        />
      )}

      <BottomNav />
    </div>
  );
}

function DetailHeader({ onBack, title }: { onBack: () => void; title: string }) {
  return (
    <header className="safe-top px-5 pt-4 pb-3 bg-white border-b border-gray-border flex items-center gap-2">
      <button
        type="button"
        onClick={onBack}
        aria-label="뒤로"
        className="w-9 h-9 -ml-1.5 rounded-full flex items-center justify-center text-text-900 text-[18px]"
      >
        ←
      </button>
      <h1 className="text-[20px] font-bold text-text-900">{title}</h1>
    </header>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className="block text-[13px] font-semibold text-text-600 mb-1.5">{label}</label>
      {children}
    </div>
  );
}

function PhotoLightbox({
  photos,
  index,
  onClose,
  onChangeIndex,
}: {
  photos: ExistingPhoto[];
  index: number;
  onClose: () => void;
  onChangeIndex: (i: number) => void;
}) {
  const hasPrev = index > 0;
  const hasNext = index < photos.length - 1;
  const [downloading, setDownloading] = useState(false);

  async function handleDownload() {
    const photo = photos[index];
    setDownloading(true);
    try {
      const res = await fetch(photo.url);
      const blob = await res.blob();
      const objectUrl = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = objectUrl;
      a.download = photo.storage_path.split('/').pop() || 'photo.jpg';
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(objectUrl);
    } finally {
      setDownloading(false);
    }
  }

  return (
    <div className="absolute inset-0 z-40 flex flex-col" style={{ background: 'rgba(0,0,0,0.95)' }}>
      <button
        type="button"
        aria-label="이미지 배경 닫기"
        onClick={onClose}
        className="absolute inset-0"
        style={{ zIndex: 0 }}
      />

      <div className="absolute top-4 right-4 flex gap-2 safe-top" style={{ zIndex: 3 }}>
        <button
          type="button"
          onClick={handleDownload}
          disabled={downloading}
          aria-label="사진 다운로드"
          className="w-9 h-9 rounded-full flex items-center justify-center text-white text-[16px] disabled:opacity-50"
          style={{ background: 'rgba(255,255,255,0.15)' }}
        >
          ⬇
        </button>
        <button
          type="button"
          onClick={onClose}
          aria-label="닫기"
          className="w-9 h-9 rounded-full flex items-center justify-center text-white text-[20px]"
          style={{ background: 'rgba(255,255,255,0.15)' }}
        >
          ×
        </button>
      </div>

      <div className="relative flex-1 flex items-center justify-center px-4" style={{ zIndex: 1 }}>
        <img
          src={photos[index].url}
          alt=""
          className="max-w-full max-h-full object-contain relative"
          style={{ zIndex: 1 }}
        />

        {hasPrev && (
          <button
            type="button"
            onClick={() => onChangeIndex(index - 1)}
            aria-label="이전 사진"
            className="absolute left-2 top-1/2 -translate-y-1/2 w-9 h-9 rounded-full flex items-center justify-center text-white text-[18px]"
            style={{ background: 'rgba(255,255,255,0.15)', zIndex: 2 }}
          >
            ‹
          </button>
        )}
        {hasNext && (
          <button
            type="button"
            onClick={() => onChangeIndex(index + 1)}
            aria-label="다음 사진"
            className="absolute right-2 top-1/2 -translate-y-1/2 w-9 h-9 rounded-full flex items-center justify-center text-white text-[18px]"
            style={{ background: 'rgba(255,255,255,0.15)', zIndex: 2 }}
          >
            ›
          </button>
        )}
      </div>

      <p className="text-center text-[12px] text-white/70 pb-6 safe-bottom relative" style={{ zIndex: 2 }}>
        {index + 1} / {photos.length}
      </p>
    </div>
  );
}
