import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocGsvascoreComponent } from './doc-gsvascore.component';

describe('DocGsvascoreComponent', () => {
  let component: DocGsvascoreComponent;
  let fixture: ComponentFixture<DocGsvascoreComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocGsvascoreComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocGsvascoreComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
