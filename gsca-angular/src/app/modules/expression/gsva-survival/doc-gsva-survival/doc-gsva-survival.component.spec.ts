import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocGsvaSurvivalComponent } from './doc-gsva-survival.component';

describe('DocGsvaSurvivalComponent', () => {
  let component: DocGsvaSurvivalComponent;
  let fixture: ComponentFixture<DocGsvaSurvivalComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocGsvaSurvivalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocGsvaSurvivalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
